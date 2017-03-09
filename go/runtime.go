package main

import (
	"fmt"
	"runtime"
)

func main() {
	fmt.Println()
	fmt.Println("# Added by runtime.go")
	fmt.Printf("_OS=%s\n", runtime.GOOS)
	fmt.Printf("_ARCH=%s\n", runtime.GOARCH)
	fmt.Println()
}
