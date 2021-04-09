#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <cstddef>
#include <string>
#include <sstream>
#include <cmath>
#include "Vector3.h"
#include "Quaternion.h"

// robot number, step number
//#define N_DRONES 5
//#define N_DRONES 7
//#define N_DRONES 9
#define N_DRONES 11

#define N_PIPUCKS (N_DRONES*4)
#define N_ROBOTS (N_DRONES+N_PIPUCKS)
#define N_STEPS 30000
#define N_PHASES 3

#define PI 3.1415926

// files
FILE *in[N_ROBOTS];
FILE *out, *out_lowerbound;

// filename strings
char dir_base[1000] = "";
char str_robots[N_ROBOTS][1000];

//desired positions and tree depth, include
//	Vector3 goal_locs[N_ROBOTS*3+1] 
//	Vector3 goal_level[N_ROBOTS*3+1] 
//#include "Ccode.cpp"
//#include "Ccode_5drones.cpp"
//#include "Ccode_7drones.cpp"
//#include "Ccode_9drones.cpp"
#include "Ccode_11drones.cpp"
//#include "Ccode_21drones.cpp"

// robot location and orientation and id for each step
int n_steps;
Vector3 locs[N_ROBOTS][N_STEPS];
Quaternion dirs[N_ROBOTS][N_STEPS];
int stepids[N_ROBOTS][N_STEPS];
double phase_error[N_STEPS];
double phase_error_lowerbound[N_STEPS];

// phases phases[0] stores the start step of phase 0
int phases[N_PHASES + 1];

int generate_csv_file_name()
{
	for (int i = 0; i < N_DRONES; i++)
	{
		std::ostringstream filename;
		filename << "drone" << i + 1 << ".csv";
		strcpy(str_robots[i], filename.str().c_str());
	}

	for (int i = 0; i < N_PIPUCKS; i++)
	{
		std::ostringstream filename;
		filename << "pipuck" << i + 1 << ".csv";
		strcpy(str_robots[i+N_DRONES], filename.str().c_str());
	}

	return 0;
}

int load_file()
{
	char filename[1000];
	for (int i = 0; i < N_ROBOTS; i++)
	{
		strcpy(filename, dir_base); 
		strcat(filename, str_robots[i]); 
		printf("loading %s\n", filename);
		in[i] = fopen(filename, "r");
		if (in[i] == NULL) {printf("open file %s failed\n", filename); return -1;}
	}

	printf("load file return 0\n");
	return 0;
}

int close_file()
{
	for (int i = 0; i < N_ROBOTS; i++)
		fclose(in[i]);
	return 0;
}

int read_data()
{
	int index;
	double info;
	double vx, vy, vz;
	double rx, ry, rz;

	for (int k = 0; k < N_PHASES + 1; k++)
		phases[k] = n_steps;

	for (int j = 0; j < n_steps; j++)
	{
		for (int i = 0; i < N_ROBOTS; i++)
		{
			fscanf(in[i], 
			       "%d,%lf,%lf,%lf,%lf,%lf,%lf,%lf\n", 
			       &index, &vx, &vy, &vz, &rz, &ry, &rx, &info
			      );

			locs[i][j].set(vx, vy, vz);
			dirs[i][j].set(Quaternion(1,0,0, rx * PI / 180) *
			               Quaternion(0,1,0, ry * PI / 180) *
			               Quaternion(0,0,1, rz * PI / 180)
			              );
			stepids[i][j] = info;

			// check phase based on the appearing time of brain id
			// default id 2 appears on step 0 (1 in csv), as the start of the first phase
			for (int k = 0; k < N_PHASES; k++)
				if ((info == N_ROBOTS*k + 2) && (j < phases[k])) phases[k] = j;

			if ((i != 0) && (i < N_DRONES) &&  // non brain drone
			    (info == 2) && (j > 1000) &&    // a non brain drone has id 2 after 1000 steps
			    (j < phases[1])
			   ) 
				phases[1] = j;
		}
	}

	printf("phases = ");
	for (int k = 0; k < N_PHASES + 1; k++)
		printf("%d, ", phases[k]);
	printf("\n");

	return 0;
}

int calc_phase_data(int start, int end, int phase_i, int stretched_length)
{
	// assume out and out_lowerbound has already opened successfully
	if (out == NULL) {printf("result file is not opened\n"); return -1;}
	if (out_lowerbound == NULL) {printf("result_lowerbound file not opened\n"); return -1;}

	// find who's brain
	int brain_i;      //robot[brain_i]
	int brain_posid = N_ROBOTS * phase_i + 2;      //robot[brain_i]
	for (int i = 0; i < N_ROBOTS; i++)
		if (stepids[i][end-1] == brain_posid) 
			brain_i = i;

	double lowerbound_error_length[N_ROBOTS];
	double time_period = 0.2;
	double default_speed = 0.03;
	double slowdown_dis = 0.35;
	double stop_dis = 0.01;

	for (int time = start; time < end; time++)
	{
		double sum_error = 0;
		double sum_lowerbound = 0;
		for (int i = 0; i < N_ROBOTS; i++)
		{
			if (stepids[i][time] == -2) continue;

			int myid = stepids[i][end-1];

			// real location to the brain
			Vector3 real_location = locs[i][time] - locs[brain_i][time];
			// target location to the brain
			Vector3 target_location = goal_locs[myid-1] - goal_locs[brain_posid-1];
			// error
			Vector3 error = real_location - target_location;
			error.z = 0;
			sum_error += error.len();

			// print error if it is the end of the phase
			if (time == end - 1)
				printf("%s : %lf\n", str_robots[i], error.len());

			// lowerbound
			if (time == start)
				lowerbound_error_length[i] = error.len();
			else
			{
				double speed = default_speed;
				if (lowerbound_error_length[i] < stop_dis)
					speed = 0;
				else if (lowerbound_error_length[i] < slowdown_dis)
					speed = default_speed * lowerbound_error_length[i] / slowdown_dis;

				if (lowerbound_error_length[i] > 0)
					lowerbound_error_length[i] -= time_period * speed;
			}
			sum_lowerbound += lowerbound_error_length[i];
		}
		sum_error /= N_ROBOTS;
		//fprintf(out, "%lf\n", sum_error);
		phase_error[time-start] = sum_error;

		sum_lowerbound /= N_ROBOTS;
		//fprintf(out_lowerbound, "%lf\n", sum_lowerbound);
		phase_error_lowerbound[time-start] = sum_lowerbound;
	}

	// everything is stored in phase_error and phase_error_lowerbound from start to end-1
	// stretch to stretched_length
	// stretch[i] should be origin[i * (origin_length)/(stretched_length)]
	//double effector = (end - start) * 1.0 / stretched_length;
	double effector = 1;  stretched_length = end-start; // no stretch
	for (int i = 0; i < stretched_length; i++)
	{
		double index_double = i * effector;
		int index = std::floor(index_double);
		double left = index_double - index;
		double error = phase_error[index+1] * left + 
		               phase_error[index]   * (1-left);
		double error_lowerbound = 
		               phase_error_lowerbound[index+1] * left + 
		               phase_error_lowerbound[index]   * (1-left);
		fprintf(out, "%lf\n", error);
		fprintf(out_lowerbound, "%lf\n", error_lowerbound);
	}

	return 0;
}

int calc_data()
{
	out = fopen("result.txt", "w");
	if (out == NULL) {printf("result file generation failed\n"); return -1;}
	out_lowerbound = fopen("result_lowerbound.txt", "w");
	if (out_lowerbound == NULL) {printf("result_lowerbound file generation failed\n"); return -1;}

	int stretched_lengths[N_PHASES] = {1200, 2800, 1200};
	for (int k = 0; k < N_PHASES; k++)
		calc_phase_data(phases[k], phases[k+1], k, stretched_lengths[k]);

	fclose(out);
	fclose(out_lowerbound);

	return 0;
}

int main(int argc, char *argv[])
{
	n_steps = atoi(argv[1]);
	printf("len = %d\n", n_steps);
	strcpy(dir_base, argv[2]);
	printf("csv_dir = %s\n", dir_base);

	if (generate_csv_file_name() != 0) return -1;
	printf("generate file names succeeded\n");

	if (load_file() != 0) return -1;
	printf("load file succeeded\n");

	read_data();
	printf("read data succeeded\n");

	close_file();
	printf("file closed and exit\n");

	calc_data();
	printf("calc data succeeded\n");

	return 0;
}
