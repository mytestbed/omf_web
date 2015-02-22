
define([], function () {

  var QTree = function (n, e, s, w, level, cx, cy) {
    if (!cx) cx = w + (e - w) / 2;
    if (!cy) cy = n + (s - n) / 2;
    var ne, se, sw, nw;
    var point;

    var ctxt = {
      n: n, e: e, s: s, w: w,
      level: level,
      point: function() {return point; },
      clear: function() { point = ne = se = sw = nw = null; }
    };

    function findQuad(q, n, e, s, w) {
      if (!q) {
        //console.log("Creating quadTree: ", n, e, s, w);
        if (level > 18) {
          var i = 0;
        }
        q = QTree(n, e, s, w, level + 1);
      }
      return q;
    }

    // Insert data into a sub quad
    function splitInsert(p) {
      var qt;
      if (p.x >= cx) {
        if (p.y >= cy) {
          qt = se = findQuad(se, cy, e, s, cx);
        } else {
          qt = ne = findQuad(ne, n, e, cy, cx);
        }
      } else {
        if (p.y >= cy) {
          qt = sw = findQuad(sw, cy, cx, s, w);
        } else {
          qt = nw = findQuad(nw, n, cx, cy, w);
        }
      }
      return qt.insertPoint(p);
    }

    ctxt.insert = function (x, y, data) {
      if (x < w || x > e || y < n || y > s) {
        throw "Insert point outside boundary";
      }
      return ctxt.insertPoint({x: x, y: y, data: data})
    };


    ctxt.insertPoint = function (p) {
      if (ne || se || sw || nw) {
        return splitInsert(p);
      } else {
        // not split yet
        if (point) {
          // let's first check if the new point has the same coordinates as the old one
          if (point.x == p.x && point.y == p.y) {
            point = p;
            return ctxt;
          }
          splitInsert(point);
          point = null;
          return splitInsert(p);
        } else {
          point = p;
          return ctxt;
        }
      }
    };

    ctxt.data = function () {
      if (point) {
        return [point.data];
      } else {
        var r = [];
        if (ne) r = r.concat(ne.data());
        if (se) r = r.concat(se.data());
        if (sw) r = r.concat(sw.data());
        if (nw) r = r.concat(nw.data());
        return r;
      }
    };

    //ctxt.isInside = function (bn, be, bs, bw) {
    //  return (n >= bn && e <= be && s <= bs && w >= bw);
    //};

    // Returns true if this quad intersects with the passed
    // in bounding box.
    ctxt.isIntersecting = function (bn, be, bs, bw) {
      var v = w <= bw && bw < e || w <= be && be < e || bw < w && be >= e;
      var h = n <= bn && bn < s || n <= bs && bs < s || bn < n && bs >= s;
      return v && h;
    };

    // Returns true if a point (x, y) is inside a bounding box
    function isInside(x, y, bn, be, bs, bw) {
      return bw <= x && x < be && bn <= y && y < bs;
    };


    ctxt.map = function(maxLevel, bn, be, bs, bw, callback) {
      if (!ctxt.isIntersecting(bn, be, bs, bw)) {
        return [];
      }
      if (point) {
        if (isInside(point.x, point.y, bn, be, bs, bw)) {
          return callback([point.data], ctxt);
        } else {
          return [];
        }
      }
      if (level >= maxLevel) {
        return callback(ctxt.data(), ctxt);
      }
      var r = [];
      if (ne) r = r.concat(ne.map(maxLevel, bn, be, bs, bw, callback));
      if (se) r = r.concat(se.map(maxLevel, bn, be, bs, bw, callback));
      if (sw) r = r.concat(sw.map(maxLevel, bn, be, bs, bw, callback));
      if (nw) r = r.concat(nw.map(maxLevel, bn, be, bs, bw, callback));
      return r;
    };

    return ctxt;
  };

  function test1() {

    var qt = QTree(0, 4, 4, 0, 0);
    qt.insert(0, 0);
    qt.insert(0, 0);

    qt.clear();
    for (var x = 0; x < 4; x++) {
      for (var y = 0; y < 4; y++) {
        qt.insert(x, y, {x: x, y: y});
      }
    }
    var m = qt.map(99, 0, 1, 1, 0, function(data_a, quad) {
      return data_a[0];
    });

    var m2 = qt.map(1, 0, 4, 4, 0, function(data_a, quad) {
      var r =  _.reduce(data_a, function(memo, data){ return memo + data.x; }, 0);
      return r;
    });

    var i = 0;
  }
  test1();

  return QTree;
});