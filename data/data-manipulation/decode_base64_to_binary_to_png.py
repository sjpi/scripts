##Used for decoding broken svg images on websites

import base64

# Your Base64 string (this is an example, replace it with your full string)
base64_string = "iVBORw0KGgoAAAANSUhEUgAAAMgAAADICAYAAACtWK6eAAAAAXNSR0IArs4c6QAAAERlWElmTU0AKgAAAAgAAYdpAAQAAAABAAAAGgAAAAAAA6ABAAMAAAABAAEAAKACAAQAAAABAAAAyKADAAQAAAABAAAAyAAAAACbWz2VAAA3JklEQVR4Ae1dCZwcRdWvmt1NAiQiJNxyyBHOACKeqAR+eIAkkt0sZDdEgyAIH/DxeYAXJir4eSsioiByJDu7ZHNxq59oQBFEOWMUAnJDQO6EI8nuTn3/f3e/mdremZ3ump6dY6d+v"

#Add padding to make the length of the string a multiple of 4
base64_string += "=" * ((4 - len(base64_string) % 4) % 4)

# Decode base64 string
try:
    image_data = base64.b64decode(base64_string)

    # Save the decoded data as a PNG image
    output_file = "converted_image.png"
    with open(output_file, "wb") as f:
        f.write(image_data)

    print(f"Image saved as {output_file}")
except Exception as e:
    print(f"Error decoding Base64: {e}")