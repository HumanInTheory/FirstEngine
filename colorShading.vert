#version 330

//uniform ivec2 screenSize;

layout(location=0) in vec2 vertexPosition;
layout(location=1) in vec2 texturePosition;
layout(location=2) in vec3 vertexColor;

out vec2 fragmentPosition;
out vec2 fragmentTexturePosition;
out vec3 fragmentColor;

void main() {
    gl_Position.x = vertexPosition.x; //((vertexPosition.x + 0.5) / (screenSize.x / 2) - 1.0);
    gl_Position.y = vertexPosition.y; //((vertexPosition.y + 0.5) / (screenSize.y / 2) - 1.0);
    gl_Position.z = 0.0;
    gl_Position.w = 1.0;

    fragmentPosition = vertexPosition;
    fragmentTexturePosition = texturePosition;
    fragmentColor = vertexColor;
}