package main

func main() {
	var i any
	i = 4
	var j int
	j, nil = i.(int)
}

// Error:
// main/files/types/assign_nil.gno:7:2: cannot assign to uverse nil
