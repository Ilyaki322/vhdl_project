# Parallel RISC Processor


## Authors:
Ilya Kirshtein

Dima Nikonov


## Overview:
In this Project, we designed a parallel RISC processor, Using the VHDL language.

This README contains:
1. Overview of the project structure.
2. Requirements to run.
3. How to run the program.



## 1. Structure:
The project contains 3 directories: vhdl, compiler, documentation

vhdl: contains all the vhdl files used in the project, each file is documented, for specific information
refer to individual documentation.

compiler: contains 3 files, python script, assembly text file and machine code assembly file.
On running the python script it will translate the contents of the assembly to machine code.

documentation: contains a presentation that explains the workings for the processor,
as well as an RTL - a block diagram that shows how components are connected within the project.



## 2. Requirements:

*Python 3.12.3 or above interpreter, no external libreries required.
*Intel ModelSim 10.5b or above to compile and run the vhdl code.

Those are the versions used in the project, earlier versions might work, use with caution.



## 3. How to run:

- Download the files of this project, and make sure you have all the requrements to run it.
- ModelSim Setup:
	- Click 'File' -> 'Change Directory'
	- Create a 'work' folder anywhere suitable ( just outside the downloaded project is recommended ) and Press 'Ok'.
	- Click 'Compile' -> navigate to the vhdl directory and compile ALL of the files.

- Getting the Assembly code ready:
	- Write the assembly program in the text files located in the compiler directory,
  	refer to the documentation slides for more information about the syntax.
	- Run the python script to compile and create a machine code file.
	- Copy the machine code file to the work directory created in the ModelSim Setup step.

- Running:
	- In ModelSim select 'Simulate' -> 'Start Simulation' and select cputb.vhdl file inside the work directory.
	- In the ModelSim console type: 'run X ns' where X is the amount of time to run, depends on how long your code is
	- If run time was not enough tpye: 'run X ns' and it will continue the program.
	- type: 'restart' to restart.

***********************************************
