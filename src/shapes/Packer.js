/**
 * 
 */
Packer = function(w, h) {
  this.root = { x: 0, y: 0, w: w, h: h };
};

Packer.prototype = {

  fit: function(blocks) {
    var n, node, block;
    for (n = 0; n < blocks.length; n++) {
      block = blocks[n];
      if (node = this.findNode(this.root, block.w, block.h))
        block.fit = this.splitNode(node, block.w, block.h);
    }
  },

  findNode: function(root, w, h) {
    if (root.used)
      return this.findNode(root.right, w, h) || this.findNode(root.down, w, h);
    else if ((w <= root.w) && (h <= root.h))
      return root;
    else
      return null;
  },

  splitNode: function(node, w, h) {
    node.used = true;
    node.down  = { x: node.x,     y: node.y + h, w: node.w,     h: node.h - h };
    node.right = { x: node.x + w, y: node.y,     w: node.w - w, h: h          };
    return node;
  }

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