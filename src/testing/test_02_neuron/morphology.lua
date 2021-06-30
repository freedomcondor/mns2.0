local dis = 0.5
return 
{	robotTypeS = "pipuck",
	positionV3 = vector3(),
	orientationQ = quaternion(),
	neuron = {
		id = "neuron_1",
		input = {neuron_2 = true, neuron_3 = true},
		output = function(input) 
			x1 = input["neuron_2"]
			x2 = input["neuron_3"]
			x3 = input["neuron_4"]
			if x1 == nil then return nil end
			if x2 == nil then return nil end
			if x3 == nil then return nil end

			return x1 + x2
		end,
	},
	children = {
	{	robotTypeS = "pipuck",
		positionV3 = vector3(-dis, -dis, 0),
		orientationQ = quaternion(0, vector3(0,0,1)),
		neuron = {
			id = "neuron_2",
			output = function(input) return 2 end
		},
	},
	{	robotTypeS = "pipuck",
		positionV3 = vector3(-dis, dis, 0),
		orientationQ = quaternion(0, vector3(0,0,1)),
		neuron = {
			id = "neuron_3",
			output = function(input) return 3 end
		},
	},
	{	robotTypeS = "pipuck",
		positionV3 = vector3(-dis, 0, 0),
		orientationQ = quaternion(0, vector3(0,0,1)),
		neuron = {
			id = "neuron_4",
			output = function(input) return 3 end
		},
		children = {
		{	robotTypeS = "pipuck",
			positionV3 = vector3(-dis, -dis/2, 0),
			orientationQ = quaternion(0, vector3(0,0,1)),
			neuron = {
				id = "neuron_5",
				output = function(input) return 2 end
			},
		},
		{	robotTypeS = "pipuck",
			positionV3 = vector3(-dis, dis/2, 0),
			orientationQ = quaternion(0, vector3(0,0,1)),
			neuron = {
				id = "neuron_6",
				output = function(input) return 2 end
			},
		},
	}},
}}
