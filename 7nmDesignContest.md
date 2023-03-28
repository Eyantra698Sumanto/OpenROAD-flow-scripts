# The OpenROAD 7nm Physical Design Contest
![image](https://user-images.githubusercontent.com/58599984/228327823-912ba30d-0127-468c-af0b-c41706387346.png)
## Design Name: Ibex
## Machine specifications
![image](https://user-images.githubusercontent.com/58599984/228325923-3019c0ab-cfc3-4a31-a623-b8bd8680f7fb.png)
## Important Links 
- [Recent Logs link](https://github.com/Eyantra698Sumanto/OpenROAD-flow-scripts/tree/7nmcontest/flow/log/asap7/ibex/base)
- [Old Logs for unchanged code](https://github.com/Eyantra698Sumanto/OpenROAD-flow-scripts/tree/7nmcontest/flow/oldlog/asap7/ibex/base)
- [OpenROAD Modified Code](https://github.com/Eyantra698Sumanto/OpenROAD-flow-scripts/tree/7nmcontest/tools/OpenROAD1/src)
## Steps followed:
1. Build and install using ```./build_openroad.sh```
2. Comment the ibex/config.mk and gcd/config.mk in the makefile at OpenROAD-flow-scripts/flow folder
  ![image](https://user-images.githubusercontent.com/58599984/228327031-cf9a1bd6-083f-421e-bc1e-d17425440b0d.png)
3. Run ```make place```
4. Note the timings from the logs
5. Change the C code in the OpenROAD-flow-scripts/tools/OpenROAD/tools
6. Repeat from **Step 1** again
## Run Time of Placement Stage without any changes
![image](https://user-images.githubusercontent.com/58599984/228294893-6f5bfca1-6386-42da-9984-0972c6a86e2b.png)
## Changes made in the gpuSolver.cu
![image](https://user-images.githubusercontent.com/58599984/228294648-7c1df1da-ca05-454f-8cf7-8aec489ac4b5.png)


### Improvement in the Placement Stage timing
![image](https://user-images.githubusercontent.com/58599984/228300190-5390745f-affb-45b8-99f0-7465afaf3bba.png)

## Changes made in nesterovPlace.cpp
![image](https://user-images.githubusercontent.com/58599984/228318635-0d807721-50e5-43c9-8b89-e968c676301a.png)

### Improvement in the Placement Stage timing
![image](https://user-images.githubusercontent.com/58599984/228318784-6d66e01f-953c-4f8b-95b7-022c0f16a582.png)

## Changes made in solver.cpp
![image](https://user-images.githubusercontent.com/58599984/228338100-e357c884-8731-41ab-96a8-e6cfcba29169.png)

### Improvement in the Placement Stage timing
![image](https://user-images.githubusercontent.com/58599984/228324932-738966d1-c5aa-481c-849c-eb550c3a912e.png)

## Changes made in fftsg.cpp rdft function
![image](https://user-images.githubusercontent.com/58599984/228340068-a972819b-7efd-45c1-8b33-170c0901b5f5.png)

### Improvement in the Placement Stage timing
![image](https://user-images.githubusercontent.com/58599984/228339817-daa6aee9-70d0-46d2-8ded-62c77061b3eb.png)

## Conclusion and Future Scope
Thus, we have obtained considerable improvement in the timings by makinf changes in the C code of each block.

Further Optimization can be done by changing the other blocks of the code and reducing the complexity of codes.

Thank You!
# Acknowledgement
1. OpenROAD Team
2. VSD and team
