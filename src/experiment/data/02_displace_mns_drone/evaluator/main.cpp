#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <cstddef>
#include "Vector3.h"
#include "Quaternion.h"

#define N_ROBOTS 15
#define N_STEPS 3600

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
	"drone5.csv",
	"drone6.csv",
	"drone7.csv",
	"drone8.csv",
	"drone9.csv",
	"drone10.csv",
	"drone11.csv",
	"drone12.csv",
	"drone13.csv",
	"drone14.csv",
	"drone15.csv",
};

double dis = 1.0;
double height= 1.5;
Vector3 goal_locs[N_ROBOTS] = {
	//1
	Vector3(),
	Vector3(-dis/3, -dis, 0),
	Vector3(-dis/3, dis, 0),

	//2
	Vector3(-dis, 0, 0),
	Vector3(-dis -dis/3, -dis, 0),
	Vector3(-dis -dis/3, dis, 0),

	//3
	Vector3(-dis*2, 0, 0),
	Vector3(-dis*2 -dis/3, -dis, 0),
	Vector3(-dis*2 -dis/3, dis, 0),

	//4
	Vector3(-dis*3, 0, 0),
	Vector3(-dis*3 -dis/3, -dis, 0),
	Vector3(-dis*3 -dis/3, dis, 0),

	//5
	Vector3(-dis*4, 0, 0),
	Vector3(-dis*4 -dis*2/3, -dis/2, 0),
	Vector3(-dis*4 -dis*2/3, dis/2, 0),
};

Vector3 locs[N_ROBOTS][N_STEPS];
Quaternion dirs[N_ROBOTS][N_STEPS];
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
		}
		ids[i] = info;
	}

	return 0;
}

int calc_data()
{
	out = fopen("result.txt", "w");
	if (out == NULL) {printf("result file generation failed\n"); return -1;}

	int head_index;
	for (int i = 0; i < N_ROBOTS; i++)
		if (ids[i] == 1)
			head_index = i;

	for (int time = 0; time < n_steps; time++)
	{
		double sum = 0;
		for (int i = 0; i < N_ROBOTS; i++)
		{
			Vector3 relative_loc = 
				dirs[head_index][time].inv().toRotate(
						locs[i][time] - locs[head_index][time])
				;

			Vector3 error = relative_loc - goal_locs[ids[i]-1];
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
