Vector3 goal_locs[N_ROBOTS*3+1] = {
	Vector3(0.0, 0.0, 1.5),
	Vector3(0.0, 0.0, 1.5),
	Vector3(-0.5, -0.5, 0.0),
	Vector3(-0.5, 0.5, 0.0),
	Vector3(0.5, 0.5, 0.0),
	Vector3(0.5, -0.5, 0.0),
	Vector3(0.0, -1.0, 1.5),
	Vector3(0.5, -1.5, 0.0),
	Vector3(-0.5, -1.5, 0.0),
	Vector3(0.5, -0.75, 0.0),
	Vector3(-0.5, -0.75, 0.0),
	Vector3(-2.2204460492503e-16, -2.0, 1.5),
	Vector3(0.5, -2.5, 0.0),
	Vector3(-0.5, -2.5, 0.0),
	Vector3(0.5, -1.75, 0.0),
	Vector3(-0.5, -1.75, 0.0),
	Vector3(-4.4408920985006e-16, -3.0, 1.5),
	Vector3(0.5, -3.5, 0.0),
	Vector3(-0.5, -3.5, 0.0),
	Vector3(0.5, -2.75, 0.0),
	Vector3(-0.5, -2.75, 0.0),
	Vector3(0.0, 1.0, 1.5),
	Vector3(-0.5, 1.5, 0.0),
	Vector3(0.5, 1.5, 0.0),
	Vector3(-0.5, 0.75, 0.0),
	Vector3(0.5, 0.75, 0.0),
	Vector3(-2.2204460492503e-16, 2.0, 1.5),
	Vector3(-0.5, 2.5, 0.0),
	Vector3(0.5, 2.5, 0.0),
	Vector3(-0.5, 1.75, 0.0),
	Vector3(0.5, 1.75, 0.0),
	Vector3(-4.4408920985006e-16, 3.0, 1.5),
	Vector3(-0.5, 3.5, 0.0),
	Vector3(0.5, 3.5, 0.0),
	Vector3(-0.5, 2.75, 0.0),
	Vector3(0.5, 2.75, 0.0),
	Vector3(0.0, 0.0, 1.5),
	Vector3(-0.5, -0.5, 0.0),
	Vector3(-0.5, 0.5, 0.0),
	Vector3(0.5, 0.5, 0.0),
	Vector3(0.5, -0.5, 0.0),
	Vector3(-1.0, 0.0, 1.5),
	Vector3(-1.5, -0.5, 0.0),
	Vector3(-1.5, 0.5, 0.0),
	Vector3(-0.75, -0.5, 0.0),
	Vector3(-0.75, 0.5, 0.0),
	Vector3(-2.0, 0.0, 1.5),
	Vector3(-2.5, -0.5, 0.0),
	Vector3(-2.5, 0.5, 0.0),
	Vector3(-1.75, -0.5, 0.0),
	Vector3(-1.75, 0.5, 0.0),
	Vector3(-3.0, 0.0, 1.5),
	Vector3(-3.5, -0.5, 0.0),
	Vector3(-3.5, 0.5, 0.0),
	Vector3(-2.75, -0.5, 0.0),
	Vector3(-2.75, 0.5, 0.0),
	Vector3(-4.0, 0.0, 1.5),
	Vector3(-4.5, -0.5, 0.0),
	Vector3(-4.5, 0.5, 0.0),
	Vector3(-3.75, -0.5, 0.0),
	Vector3(-3.75, 0.5, 0.0),
	Vector3(-5.0, 0.0, 1.5),
	Vector3(-5.5, -0.5, 0.0),
	Vector3(-5.5, 0.5, 0.0),
	Vector3(-4.75, -0.5, 0.0),
	Vector3(-4.75, 0.5, 0.0),
	Vector3(-6.0, 0.0, 1.5),
	Vector3(-6.5, -0.5, 0.0),
	Vector3(-6.5, 0.5, 0.0),
	Vector3(-5.75, -0.5, 0.0),
	Vector3(-5.75, 0.5, 0.0),
	Vector3(0.0, 0.0, 1.5),
	Vector3(-0.5, -0.5, 0.0),
	Vector3(-0.5, 0.5, 0.0),
	Vector3(0.5, 0.5, 0.0),
	Vector3(0.5, -0.5, 0.0),
	Vector3(0.0, -1.0, 1.5),
	Vector3(0.5, -1.5, 0.0),
	Vector3(-0.5, -1.5, 0.0),
	Vector3(0.5, -0.75, 0.0),
	Vector3(-0.5, -0.75, 0.0),
	Vector3(0.58778525229247, -1.8090169943749, 1.5),
	Vector3(1.2861863756262, -1.9196328654162, 0.0),
	Vector3(0.47716938125124, -2.5074181177087, 0.0),
	Vector3(0.84534743640683, -1.312870119635, 0.0),
	Vector3(0.036330442031881, -1.9006553719274, 0.0),
	Vector3(1.5388417685876, -2.1180339887499, 1.5),
	Vector3(2.1688785239227, -1.7970142277898, 0.0),
	Vector3(1.8598615295477, -2.7480707440849, 0.0),
	Vector3(1.4555861367013, -1.5652514820086, 0.0),
	Vector3(1.1465691423264, -2.5163079983037, 0.0),
	Vector3(0.0, 1.0, 1.5),
	Vector3(-0.5, 1.5, 0.0),
	Vector3(0.5, 1.5, 0.0),
	Vector3(-0.5, 0.75, 0.0),
	Vector3(0.5, 0.75, 0.0),
	Vector3(0.58778525229247, 1.8090169943749, 1.5),
	Vector3(0.47716938125124, 2.5074181177087, 0.0),
	Vector3(1.2861863756262, 1.9196328654162, 0.0),
	Vector3(0.036330442031881, 1.9006553719274, 0.0),
	Vector3(0.84534743640683, 1.312870119635, 0.0),
	Vector3(1.5388417685876, 2.1180339887499, 1.5),
	Vector3(1.8598615295477, 2.7480707440849, 0.0),
	Vector3(2.1688785239227, 1.7970142277898, 0.0),
	Vector3(1.1465691423264, 2.5163079983037, 0.0),
	Vector3(1.4555861367013, 1.5652514820086, 0.0),
};
int goal_level[N_ROBOTS*3+1] = {
1, 2, 3, 3, 3, 3, 3, 4, 4, 4, 4, 4, 5, 5, 5, 5, 5, 6, 6, 6, 6, 3, 4, 4, 4, 4, 4, 5, 5, 5, 5, 5, 6, 6, 6, 6, 2, 3, 3, 3, 3, 3, 4, 4, 4, 4, 4, 5, 5, 5, 5, 5, 6, 6, 6, 6, 6, 7, 7, 7, 7, 7, 8, 8, 8, 8, 8, 9, 9, 9, 9, 2, 3, 3, 3, 3, 3, 4, 4, 4, 4, 4, 5, 5, 5, 5, 5, 6, 6, 6, 6, 3, 4, 4, 4, 4, 4, 5, 5, 5, 5, 5, 6, 6, 6, 6, };
