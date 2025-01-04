## Testing of app scaling logic and more.

## Will consume all your memory WHEN configured properly.
## EXAMPLE: Each block is approximately 4MB, and the total memory requirement for 4096 blocks is about 16GB

import numpy

try:
    result = [numpy.random.bytes(2048*2048) for x in range(4096)]
    print(len(result))
except MemoryError:
    print("Memory exceeded. Couldn't allocate the requested dataz.")
    result = []  # Free up the memories if your sweet heart desires..