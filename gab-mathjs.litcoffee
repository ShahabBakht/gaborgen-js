# WARNING

This was my first implementation in MathJS. It's hundreds of times slower compared to the numericjs one, but I'll leave it here for reference.

# Gabor patch generator

Uses [PNGlib](http://www.xarg.org/2010/03/generate-client-side-png-files-using-javascript/), which has a BSD license.

Constants

	#pi = 3.1416 # matlab's value # we'll use math.js's
	reso = 400 # should be 400, lowered for testing
	phase = 0
	sc = 50.0
	contrast = 100.0
	aspectratio = 1.0
	tilt = 45 # ranges from 0 to 90
	sf = .07 # ranges from .01 to .1

Now math. This function converts degrees to radians.

	deg2rad = (degrees) ->
		degrees * math.pi / 180

`meshgrid` takes an array then replicates it `l` times and returns a matrix, where `l` is the array's length.

	meshgrid = (value) ->
		m = []
		value_length = value.length
		i = 0
		while i < value_length
			m.push(value)
			i += 1
		[m, math.transpose(m)]

Lay groundwork. Right now this assumes square gabor patches. This makes heavy use of [mathjs](http://mathjs.org). This is a construction based on the OCTAVE/MATLAB code from Wikipedia.

	x = reso / 2
	y = reso / 2
	#a = math.cos(deg2rad(tilt)) * sf * 360
	#b = math.sin(deg2rad(tilt)) * sf * 360
	a = math.cos(math.unit(tilt, 'deg')) * sf * 360
	b = math.sin(math.unit(tilt, 'deg')) * sf * 360
	multConst = 1 / (math.sqrt(2 * math.pi) * sc)
	varScale = 2 * math.pow(sc, 2)
	gridArray = math.range(0, reso)._data # that last bit is b/c mathjs is weird
	[gab_x, gab_y] = meshgrid(gridArray)
	x_centered = math.subtract(gab_x, x)
	y_centered = math.subtract(gab_y, y)
	x_factor = math.multiply(math.square(x_centered), -1)
	y_factor = math.multiply(math.square(y_centered), -1)
	preSinWave = math.add(math.add(math.multiply(a, x_centered), math.multiply(b, y_centered)), phase)
	# sinWave = math.sin math.map(preSinWave, (value) ->
	# 	math.unit(value, 'deg').value)

The above (commented out) way of using `math.map` to traverse the matrix is horrible. Let's try something else.

	i = 0
	while i < reso
		j = 0
		while j < reso
			preSinWave[i][j] = deg2rad(preSinWave[i][j])
			j+=1
		i+=1

There. Now, let's continue.

	sinWave = math.sin(preSinWave)
	m = math.add(.5, math.multiply(contrast, math.transpose(math.dotMultiply(math.multiply(multConst, math.exp(math.add(math.divide(x_factor, varScale), math.divide(y_factor, varScale)))), sinWave))))

Now we have a matrix of values. Matlab has the wonderful and magical `imshow` command that just takes the matrix and makes a picture. We have to do that magic ourselves. So to use the matrix `m` in the pnglib code below, we have to rescale all the values to be between 0 and 255, the intensity values for each pixel. The first function is a core function we'll wrap up later for clarity. This is based on [Gabriel Peyre](http://www.mathworks.com/matlabcentral/fileexchange/5103-toolbox-diffc/content/toolbox_diffc/toolbox/rescale.m)'s 2004 `rescale.m`, which uses a BSD license.

	rescale_core = (y, a, b, m, M) ->
		y if M - m < .0000001
		math.add(math.multiply(b - a, math.divide(math.subtract(y, m), M - m)), a)

	rescale = (y, a, b) ->
		rescale_core(y, a, b, math.min(y), math.max(y))

Finally, we rescale the image matrix to be between 0 and 255.

	scaledM = rescale(m, 0, 255)


# Display the picture.

Now we create a PNG element and loop through it, changing each pixel's color.

	p = new PNGlib(reso, reso, 256)
	# construcor takes height, weight and color-depth
	background = p.color(0, 0, 0, 0)
	# set the background transparent
	i = 0
	while i < reso
		j = 0
		while j < reso
			grayval = scaledM[i][j]
			p.buffer[p.index(i, j)] = p.color(grayval, grayval, grayval)
			#p.buffer[p.index(i + 90, j + 135)] = p.color(0xcc, 0xcc, 0xcc)
			#p.buffer[p.index(i + 80, j + 120)] = p.color(0x44, 0x44, 0x44)
			#p.buffer[p.index(i + 100, j + 130)] = p.color(0x00, 0x00, 0x00)
			j++
		i++
	the_image = '<img src="data:image/png;base64,' + p.getBase64() + '">'

And finally write the output to the DOM element.

	$('#gab-target').html(the_image)
