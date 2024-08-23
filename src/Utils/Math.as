namespace Math {
	vec3 Fract(const vec3 &in c) {
		return vec3(Math::Fract(c.x),Math::Fract(c.y),Math::Fract(c.z));
	}

	vec3 Clamp(const vec3 &in c, const float min, const float max) {
		return vec3(Math::Clamp(c.x,min,max),Math::Clamp(c.y,min,max),Math::Clamp(c.z,min,max));
	}

	vec3 Abs(const vec3 &in c) {
		return vec3(Math::Abs(c.x),Math::Abs(c.y),Math::Abs(c.z));
	}

	float Fract(const float v) {
		return v - Math::Floor(v);
	}
}