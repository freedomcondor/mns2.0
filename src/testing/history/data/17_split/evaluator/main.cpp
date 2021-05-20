#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <cstddef>
#include "Vector3.h"
#include "Quaternion.h"

#define N_ROBOTS 14
#define N_STEPS 5500

#define PI 3.1415926

FILE *in[N_ROBOTS];
FILE *out;

int n_steps;

char dir_base[200] = "";
char str_robots[N_ROBOTS][100] = {
	"drone1.csv",
	"drone2.csv",
	"drone3.csv",
	"drone4.csv",
	"pipuck1.csv",
	"pipuck2.csv",
	"pipuck3.csv",
	"pipuck4.csv",
	"pipuck5.csv",
	"pipuck6.csv",
	"pipuck7.csv",
	"pipuck8.csv",
	"pipuck9.csv",
	"pipuck10.csv",
};

double dis = 1.0;
double height= 1.5;
Vector3 goal_locs[26] = 
{
	Vector3(0.0, 0.0, 1.5),
	Vector3(0.0, 0.0, 1.5),
	Vector3(-0.5, -0.5, 0.0),
	Vector3(-0.5, 0.5, 0.0),
	Vector3(0.5, 0.5, 0.0),
	Vector3(0.5, -0.5, 0.0),
	Vector3(0.0, -1.3, 1.5),
	Vector3(0.5, -1.8, 0.0),
	Vector3(-0.5, -1.8, 0.0),
	Vector3(0.0, 0.0, 1.5),
	Vector3(-0.5, -0.5, 0.0),
	Vector3(-0.5, 0.5, 0.0),
	Vector3(0.5, 0.5, 0.0),
	Vector3(0.5, -0.5, 0.0),
	Vector3(1.3, 0.0, 1.5),
	Vector3(1.8, -0.5, 0.0),
	Vector3(1.8, 0.5, 0.0),
	Vector3(0.0, -1.3, 1.5),
	Vector3(-0.5, -1.8, 0.0),
	Vector3(0.5, -1.8, 0.0),
	Vector3(-1.3, 0.0, 1.5),
	Vector3(-1.8, 0.5, 0.0),
	Vector3(-1.8, -0.5, 0.0),
	Vector3(0.0, 0.0, 1.5),
	Vector3(-0.5, -0.5, 0.0),
	Vector3(-0.5, 0.5, 0.0),
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

		printf("robot: %s : %d\n", str_robots[i], ids[i]);
	}

	return 0;
}

int calc_data()
{
	out = fopen("result.txt", "w");
	if (out == NULL) {printf("result file generation failed\n"); return -1;}

	for (int time = 0; time < n_steps; time++)
	{
		double sum = 0;
		for (int i = 0; i < N_ROBOTS; i++)
		{
			int head_id;
			int head_index;
			int head_goal_index;
			// find the nearest head id
			if (stepids[i][time] >= 2) head_id = 2;
			if (stepids[i][time] >= 10) head_id = 10;
			if (stepids[i][time] >= 24) head_id = 24;
			// find the nearest head robot
			double distance = 99999999;
			for (int j = 0; j < N_ROBOTS; j++)
				if ((stepids[j][time] == head_id) &&
				    ((locs[i][time] - locs[j][time]).len() < distance)) 
				{
					distance = (locs[i][time] - locs[j][time]).len();
					head_index = j;
					head_goal_index = head_id - 1;
				}

			// hack for logical direction
			if ((head_id == 24) && (head_index == 2)) dirs[head_index][time] = Quaternion(Vector3(0,0,1), PI);
			if ((head_id == 24) && (head_index == 3)) dirs[head_index][time] = Quaternion(Vector3(0,0,1), PI/2);
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
