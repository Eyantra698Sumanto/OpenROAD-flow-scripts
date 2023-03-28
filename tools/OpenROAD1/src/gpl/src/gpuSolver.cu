/////////////////////////////////////////////////////////////////////////////
//
// BSD 3-Clause License
//
// Copyright (c) 2019, The Regents of the University of California
// All rights reserved.
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are met:
//
// * Redistributions of source code must retain the above copyright notice, this
//   list of conditions and the following disclaimer.
//
// * Redistributions in binary form must reproduce the above copyright notice,
//   this list of conditions and the following disclaimer in the documentation
//   and/or other materials provided with the distribution.
//
// * Neither the name of the copyright holder nor the names of its
//   contributors may be used to endorse or promote products derived from
//   this software without specific prior written permission.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
// AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
// IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
// ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
// LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
// CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
// SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
// INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
// CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
// ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
// POSSIBILITY OF SUCH DAMAGE.
//
///////////////////////////////////////////////////////////////////////////////

#include <cusp/precond/diagonal.h>
#include <cusp/blas/blas.h>
#include <cusp/krylov/bicgstab.h>

#include "gpuSolver.h"

namespace gpl {
using namespace std;
using utl::GPL;



void GpuSolver::cudaerror(cudaError_t code)
{
  if (code != cudaSuccess) {
    log_->error(GPL,
                1,
                "[CUDA ERROR] {} at line {} in file {} \n",
                cudaGetErrorString(code),
                __LINE__,
                __FILE__);
  }
}
void GpuSolver::cusparseerror(cusparseStatus_t code)
{
  if (code != CUSPARSE_STATUS_SUCCESS) {
    log_->error(GPL,
                1,
                "[CUSPARSE ERROR] {} at line {} in file {}\n",
                cusparseGetErrorString(code),
                __LINE__,
                __FILE__);
  }
}

void GpuSolver::cusolvererror(cusolverStatus_t code)
{
  if (code != CUSOLVER_STATUS_SUCCESS) {
    log_->error(GPL,
                1,
                "[CUSOLVER ERROR] {} at line {} in file {}\n",
                cudaGetErrorString(*(cudaError_t*) &code),
                __LINE__,
                __FILE__);
  }
}

GpuSolver::GpuSolver(SMatrix& placeInstForceMatrix,
                     Eigen::VectorXf& fixedInstForceVec,
                     utl::Logger* logger)
{
  // Convert the sparse matrix to COO format on the host
  const int nnz = placeInstForceMatrix.nonZeros();
  vector<int> cooRowIndex(nnz), cooColIndex(nnz);
  vector<float> cooVal(nnz);
  int cnt = 0;
  for (int row = 0; row < placeInstForceMatrix.outerSize(); row++) {
    for (typename SMatrix::InnerIterator it(placeInstForceMatrix, row); it; ++it) {
      cooRowIndex[cnt] = it.row();
      cooColIndex[cnt] = it.col();
      cooVal[cnt] = it.value();
      cnt++;
    }
  }

  // Copy the COO formatted triplets to device
  d_cooRowIndex_ = cooRowIndex;
  d_cooColIndex_ = cooColIndex;
  d_cooVal_ = cooVal;
  d_instLocVec_.resize(fixedInstForceVec.size());

  // Set raw pointers to point to the triplets in the device
  r_cooRowIndex_ = d_cooRowIndex_.data();
  r_cooColIndex_ = d_cooColIndex_.data();
  r_cooVal_ = d_cooVal_.data();
  r_instLocVec_ = d_instLocVec_.data();

  m_ = fixedInstForceVec.size();
  log_ = logger;
}


void GpuSolver::cusolverCal(Eigen::VectorXf& instLocVec)
{
  // Updated CUDA solver using CUSP library
  thrust::device_ptr<int> p_rowInd
      = thrust::device_pointer_cast(r_cooRowIndex_);
  thrust::device_ptr<int> p_colInd
      = thrust::device_pointer_cast(r_cooColIndex_);
  thrust::device_ptr<float> p_val = thrust::device_pointer_cast(r_cooVal_);
  thrust::device_ptr<float> d_fixedInstForceVec_
      = thrust::device_pointer_cast(r_fixedInstForceVec_);
  thrust::device_ptr<float> p_instLocVec_ = thrust::device_pointer_cast(r_instLocVec_);

  // use array1d_view to wrap the individual arrays
  typedef typename cusp::array1d_view<thrust::device_ptr<int>>
      DeviceIndexArrayView;
  typedef typename cusp::array1d_view<thrust::device_ptr<float>>
      DeviceValueArrayView;
  DeviceIndexArrayView row_indices(p_rowInd, p_rowInd + nnz_);
  DeviceIndexArrayView column_indices(p_colInd, p_colInd + nnz_);
  DeviceValueArrayView values(p_val, p_val + nnz_);
  DeviceValueArrayView d_x(p_instLocVec_, p_instLocVec_ + m_);
  DeviceValueArrayView d_b(d_fixedInstForceVec_, d_fixedInstForceVec_ + m_);

  // combine the three array1d_views into a coo_matrix_view
  typedef cusp::coo_matrix_view<DeviceIndexArrayView,
                                DeviceIndexArrayView,
                                DeviceValueArrayView>
      DeviceView;

  // construct a coo_matrix_view from the array1d_views
  DeviceView d_A(m_, m_, nnz_, row_indices, column_indices, values);

  // set stopping criteria.
  int iteration_limit = 100;
  float relative_tolerance = 1e-15;
  bool verbose = false;  // Decide if the CUDA solver prints the iteration
                         // details or not.
  cusp::monitor<float> monitor_(
      d_b, iteration_limit, relative_tolerance, verbose);

  // setup preconditioner
  cusp::precond::diagonal<float, cusp::device_memory> d_M(d_A);

  // solve the linear system A * x = b with the BICGSTAB method
  cusp::krylov::bicgstab(d_A, d_x, d_b, monitor_, d_M);

  // Sync and Copy data to host
  cudaerror(cudaMemcpy(instLocVec.data(),
                       r_instLocVec_,
                       sizeof(float) * m_,
                       cudaMemcpyDeviceToHost));

  // Calculate  AX = A * X - B
  cusp::coo_matrix<int, float, cusp::device_memory> A(d_A);
  cusp::array1d<float, cusp::device_memory> X(d_x);
  cusp::array1d<float, cusp::device_memory> B(d_b);
  cusp::array1d<float, cusp::device_memory> AX(m_);
  cusp::multiply(A, X, AX);
  cusp::blas::axpy(B, AX, -1);

  // Calculate L1 norm of the residual vector.
  error_ = cusp::blas::nrm1(AX) / cusp::blas::nrm1(B);
}

float GpuSolver::error()
{
  return (error_ > 0) ? error_ : -error_;
}

GpuSolver::~GpuSolver()
{
}
}  // namespace gpl
