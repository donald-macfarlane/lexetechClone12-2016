graph.dot: nothing
	pogo index.pogo > graph.dot

nothing:

graph.png: graph.dot
	dot -Tpng graph.dot > graph.png
	open graph.png