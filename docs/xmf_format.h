// header
char magic[4];      // = {'X', 'U', 'M', 'F'}
short version;      // 0x0003 (3) ???
short chunkOffset;  // 0x0040 (64) ???
char chunkCount;    // 2 <= N <= 11
char chunkSize;     // 0x38 | 0xBC (56 | 188)
char materialCount;
char unknown1;      // 0x88 (136)
char unknown2;      // 0x01 (1)
char unknown3;      // 0x00 (0)
int vertexCount;
int indexCount;     // (number of triangles) x 3
int unknown4;       // 0x00000004 (4)
int unknown5;       // 0x00000001 (1)
char zeros[34];      // 34 x 0x00

// chunks
// absolute offset (64)
{
    int id1;            // 0|3|4|6|8|30
    int part;           // 0x00, sometimes 0x01 (when current.id1 == prevouis.id1)
    int offset          // relative to gzipped data start
    int one1;           // 0x00000001 (1)
    int zero;           // 0x00000000 (0)
    int id2;            // 2|4|15|16|30|31|32
    int size;           // packed size
    int elementCount;
    int bytesPerElement;
    int one2;           // 0x00000001 (1)
    char unknownData[chunkSize - 40];
}
// ...
// repeat (chunkCount) times


// materials
// absolute offset (64 + chunkCount * chunkSize)
if materialCount > 0 {
    {
        int indexStart;
        int indexCount;
        char materialName[128];
    }
    // ...
    // repeat (materialCount) times
}

// gzipped data
// absolute offset (64 + (chunkCount*chunkSize) + (materialCount*136))
char data[];
