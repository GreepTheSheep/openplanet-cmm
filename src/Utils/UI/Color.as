namespace UI {
    string CreateColorCode(const vec3 &in input) {
        string ReturnedValue = "\\$";
        ReturnedValue += Text::Format("%x", uint8(input.x * 15.0));
        ReturnedValue += Text::Format("%x", uint8(input.y * 15.0));
        ReturnedValue += Text::Format("%x", uint8(input.z * 15.0));
        return ReturnedValue;
    }

    vec3 hsv2rgb(const vec3 &in c) {
        vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
        vec3 p = Math::Abs(Math::Fract(vec3(c.x,c.x,c.x) + vec3(K.x,K.y,K.z)) * 6.0 - vec3(K.w,K.w,K.w));
        return Math::Lerp(vec3(K.x,K.x,K.x), Math::Clamp(p - vec3(K.x,K.x,K.x), 0.0, 1.0), c.y) * c.z;
    }
}