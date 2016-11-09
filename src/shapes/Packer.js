/**
 * 
 */
Packer = function(w, h) {
  this.root = { x: 0, y: 0, w: w, h: h, used: false };
};

Packer.prototype = {

  fit: function(blocks) {
    var n, node, block;
    for (n = 0; n < blocks.length; n++) {
      block = blocks[n];
      if (node = this.findNode(this.root, block.w, block.h)) {
        block.fit = this.splitNode(node, block.w, block.h);
        }
    }
  },

  findNode: function(root, w, h) {
    if (root.used)
      return this.findNode(root.right, w, h) || this.findNode(root.down, w, h);
    else if ((w <= root.w) && (h <= root.h)) {
      return root;
      }
    else
      return null;
  },

  splitNode: function(node, w, h) {
    node.used = true;
    node.down  = { x: node.x,     y: node.y + h, w: node.w,     h: node.h - h, used:false };
    node.right = { x: node.x + w, y: node.y,     w: node.w - w, h: h , used: false         };
    return node;
  }

}

function runPacker(id, blocks, w, h) {
	var packer = new Packer(w, h);   // or:  new GrowingPacker();
	blocks.sort(function(a,b) {return (b.h == a.h? 0:(b.h>a.h?1:-1)); }); // sort inputs for best results
	packer.fit(blocks);
	var width = 0;
	var height = 0;
	for(var n = 0 ; n < blocks.length ; n++) {
		  var block = blocks[n];
		  if (block.fit) {
		         // p.append("use").attr("xlink:href","#g_"+block.id).attr("x",block.fit.x).attr("y", block.fit.y);
			    var c = d3.select("#"+block.id+"_svg");
			    c.attr("x", block.fit.x).attr("y", block.fit.y);
			    var google = !d3.select("#" + block.id + "_fo").empty()
			       && !d3.select("#" + block.id + "_fo").select(".google").empty();
			    if (google) d3.select("#" + block.id + "_fo").attr("x", block.fit.x).attr("y", block.fit.y);
			    if (block.fit.x+block.w>width) width = block.fit.x+block.w;
			    if (block.fit.y+block.h>height) height = block.fit.y+block.h;
		  }
		}
	var p = d3.select("#"+id);
	p.attr("width", width).attr("height", height);
	d3.select("#"+id+"_svg").attr("width", width+1).attr("height", height+1);
    }
/*
var packer = new Packer(1000, 1000);   // or:  new GrowingPacker();
var blocks = [
  { w: 100, h: 100 },
  { w: 100, h: 100 },
  { w:  80, h:  80 },
  { w:  80, h:  80 },
  etc
  etc
];

blocks.sort(function(a,b) { return (b.h < a.h); }); // sort inputs for best results
packer.fit(blocks);

for(var n = 0 ; n < blocks.length ; n++) {
  var block = blocks[n];
  if (block.fit) {
    DrawRectangle(block.fit.x, block.fit.y, block.w, block.h);
  }
}
*/