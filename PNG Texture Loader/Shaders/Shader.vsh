//
//  Shader.vsh
//  PNG Texture Loader
//
//  Created by numata on 09/09/12.
//  Copyright Satoshi Numata 2009. All rights reserved.
//

attribute vec4 position;
attribute vec4 color;

varying vec4 colorVarying;

uniform float translate;

void main()
{
	gl_Position = position;
	gl_Position.y += sin(translate) / 2.0;
	
	colorVarying = color;
}
