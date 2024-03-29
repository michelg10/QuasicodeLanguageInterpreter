#ifndef object_h
#define object_h

struct ObjString {
    long length;
    unsigned char* data;
};

struct ObjArray {
    long length;
    unsigned long* data;
};

struct ObjInstance {
    long* fields;
};

struct ObjString* compilerCopyString(const char* chars, long length);

#endif /* object_h */
