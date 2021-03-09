#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <cstddef>
#include <string>
#include <sstream>
#include "Vector3.h"
#include "Quaternion.h"

#define N_DRONES 4
#define N_PIPUCKS 4
#define N_ROBOTS (N_DRONES+N_PIPUCKS)
#define N_STEPS 1000

#define PI 3.1415926

FILE *in[N_ROBOTS];
FILE *out, *out_lowerbound;

int n_steps;

char dir_base[200] = "";
char str_robots[N_ROBOTS][100];

#include "Ccode.cpp"

Vector3 locs[N_ROBOTS][N_STEPS];
Quaternion dirs[N_ROBOTS][N_STEPS];
int stepids[N_ROBOTS][N_STEPS];
int ids[N_ROBOTS];

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

	for (int i = 0; i < N_ROBOTS; i++)
		printf("%s\n", str_robots[i]);

	printf("generating csv files done\n");

	return 0;
}

int load_file()
{
	char filename[100];
	for (int i = 0; i < N_ROBOTS; i++)
	{
		strcpy(filename, dir_base); 
		strcat(filename, str_robots[i]); 
		in[i] = fopen(filename, "r");
		if (in[i] == NULL) {printf("open file %s failed\n", filename); return -1;}
	}

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

	for (int i = 0; i < N_ROBOTS; i++)
	{
		for (int j = 0; j < n_steps; j++)
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
		}
		ids[i] = info;

		double period_id = info;
		for (int j = n_steps-1; j >= 0; j--)
		{
			if (stepids[i][j] == -1)
				stepids[i][j] = period_id;
			else
				period_id = stepids[i][j];
		}

		printf("robot: %s : %d\n", str_robots[i], ids[i]);
	}

	return 0;
}

int calc_data()
{
	out = fopen("result.txt", "w");
	if (out == NULL) {printf("result file generation failed\n"); return -1;}
	out_lowerbound = fopen("result_lowerbound.txt", "w");
	if (out_lowerbound == NULL) {printf("result_lowerbound file generation failed\n"); return -1;}

	for (int time = 0; time < n_steps; time++)
	{
		// check each robot
		double sum = 0;
		double sum_lowerbound = 0;
		for (int i = 0; i < N_ROBOTS; i++)
		{
			int head_id;
			int head_index;
			int head_goal_index;
			// find the nearest head id
			if (stepids[i][n_steps-1] >= 1) head_id = 1;

			// find head from the final step of the phase
			for (int j = 0; j < N_DRONES; j++)
				if (stepids[j][n_steps-1] == head_id)
				{
					head_index = j;
					head_goal_index = head_id - 1;
				}

			int level_difference = 
				goal_level[stepids[i][n_steps-1]-1] - 1;

			Vector3 relative_loc = 
				dirs[head_index][time].inv().toRotate(
						locs[i][time]-locs[head_index][time]
				)
				;

			Vector3 relative_loc_lowerbound = 
				dirs[head_index][time-level_difference].inv().toRotate(
						locs[i][time]-locs[head_index][time-level_difference]
				)
				;

			printf("time = %d, robot = %s,\n\trelative_loc = %s,\n\t relative_loc_lowerbound = %s\n",
			               time+1, str_robots[i], relative_loc.toStr(), relative_loc_lowerbound.toStr());
			printf("\ttarget = %s\n", (goal_locs[stepids[i][n_steps-1]-1] - goal_locs[head_goal_index]).toStr());
			printf("\tlevel_difference = %d\n", level_difference);

			//Vector3 error = relative_loc - (goal_locs[ids[i]-1] - goal_locs[head_goal_index]);
			Vector3 error = relative_loc - 
			                (goal_locs[stepids[i][n_steps-1]-1] - goal_locs[head_goal_index]);
			Vector3 error_lowerbound = relative_loc_lowerbound - 
			                (goal_locs[stepids[i][n_steps-1]-1] - goal_locs[head_goal_index]);
			sum += error.len();
			sum_lowerbound += error_lowerbound.len();
			
			//if (time == n_steps - 1)
			printf("real       %s %lf\n", str_robots[i], error.len());
			printf("lowerbound %s %lf\n", str_robots[i], error_lowerbound.len());
		}
		sum /= N_ROBOTS;
		sum_lowerbound /= N_ROBOTS;
		fprintf(out, "%lf\n", sum);
		fprintf(out_lowerbound, "%lf\n", sum_lowerbound);
	}


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

	if (load_file() != 0) return -1;
	printf("load file succeeded\n");

	read_data();
	printf("read data succeeded\n");

	calc_data();
	printf("calc data succeeded\n");

	close_file();
	printf("file closed and exit\n");

	return 0;
}
