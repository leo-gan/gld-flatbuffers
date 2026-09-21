from flatbuffers import Builder, FlexBuilder

def main():
    var b = Builder(32)
    _ = b
    var flex = FlexBuilder()
    _ = flex
    print("mojo-flatbuffers import ok")
