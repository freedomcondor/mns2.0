#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <cstddef>
#include "Vector3.h"
#include "Quaternion.h"

#define N_ROBOTS 8
#define N_STEPS 5500

#define PI 3.1415926

FILE *in[N_ROBOTS];
FILE *out;

int n_steps;

char dir_base[200] = "";
char str_robots[N_ROBOTS][100] = {
	"drone1.csv",
	"drone2.csv",
	"pipuck1.csv",
	"pipuck2.csv",
	"pipuck3.csv",
	"pipuck4.csv",
	"pipuck5.csv",
	"pipuck6.csv",
};

double dis = 1.0;
double height= 1.5;
Vector3 goal_locs[N_ROBOTS * 3 + 1] = 
{
	Vector3(0.0, 0.0, 1.5),
	Vector3(0.0, 0.0, 1.5),
	Vector3(-0.6, -0.6, 0.0),
	Vector3(-0.6, 0.6, 0.0),
	Vector3(0.6, 0.6, 0.0),
	Vector3(0.6, -0.6, 0.0),
	Vector3(0.0, -1.2, 1.5),
	Vector3(0.6, -1.8, 0.0),
	Vector3(-0.6, -1.8, 0.0),
	Vector3(0.0, 0.0, 1.5),
	Vector3(-0.3, 0.0, 0.0),
	Vector3(-0.45, 0.6, 0.0),
	Vector3(-0.45, -0.6, 0.0),
	Vector3(0.3, 0.0, 0.0),
	Vector3(0.45, 0.6, 0.0),
	Vector3(0.45, -0.6, 0.0),
	Vector3(-1.2, 0.0, 1.5),
	Vector3(0.0, 0.0, 1.5),
	Vector3(0.075, 0.0, 0.0),
	Vector3(0.15, 0.2, 0.0),
	Vector3(0.3, 0.3, 0.0),
	Vector3(0.15, -0.2, 0.0),
	Vector3(0.3, -0.3, 0.0),
	Vector3(-0.6, 0.0, 0.0),
	Vector3(-1.2, 0.0, 1.5),
};



Vector3 locs[N_ROBOTS][N_STEPS];
Quaternion dirs[N_ROBOTS][N_STEPS];
int stepids[N_ROBOTS][N_STEPS];
int ids[N_ROBOTS];

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
	}

	return 0;
}

int calc_data()
{
	out = fopen("result.txt", "w");
	if (out == NULL) {printf("result file generation failed\n"); return -1;}

	for (int time = 0; time < n_steps; time++)
	{
		int head_index;
		int head_goal_index;
		for (int i = 0; i < N_ROBOTS; i++)
		{
			if ((stepids[i][time] == 2) || 
		    	(stepids[i][time] == 2 + N_ROBOTS * 1) || 
		    	(stepids[i][time] == 2 + N_ROBOTS * 2)
		   	   )
				head_index = i;
			if (stepids[i][time] == 2) head_goal_index = 1;
			if (stepids[i][time] == 2 + N_ROBOTS * 1) head_goal_index = 1 + N_ROBOTS * 1;
			if (stepids[i][time] == 2 + N_ROBOTS * 2) head_goal_index = 1 + N_ROBOTS * 2;
		}
		
		double sum = 0;
		for (int i = 0; i < N_ROBOTS; i++)
		{
			Vector3 relative_loc = 
				dirs[head_index][time].inv().toRotate(
						locs[i][time] - locs[head_index][time])
				;

			//Vector3 error = relative_loc - (goal_locs[ids[i]-1] - goal_locs[head_goal_index]);
			Vector3 error = relative_loc - (goal_locs[stepids[i][time]-1] - goal_locs[head_goal_index]);
			sum += error.len();
			
			if (time == n_steps - 1)
				printf("%s %lf\n", str_robots[i], error.len());
		}
		sum /= N_ROBOTS;
		fprintf(out, "%lf\n", sum);
	}

	fclose(out);

	return 0;
}

int main(int argc, char *argv[])
{
	n_steps = atoi(argv[1]);
	printf("len = %d\n", n_steps);
	strcpy(dir_base, argv[2]);
	printf("csv_dir = %s\n", dir_base);

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
