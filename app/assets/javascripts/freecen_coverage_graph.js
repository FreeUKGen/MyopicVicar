//values into the range of pixels coorinates (do x and y individually)
function xform_point(xin,xin_min,xin_max,xout_min,xout_max,inverted){
  var xp = xout_min;
  if(xin_max-xin_min != 0)
    xp = (xin-xin_min) * (xout_max-xout_min) / (xin_max-xin_min);
  if(inverted)
    xp = xout_max - xp;
  return xp;
}

//draw the graph. requires graph_canvas and text_canvas in the html page
function drawCoverageGraph(graph_canvas_id, text_canvas_id, points, xLabel, yLabel, leftTicks, bottomTicks,x_min_value,x_max_value,y_min_value,y_max_value,top_margin,left_margin,right_margin,bottom_margin,canvas_w,canvas_h){

  var canv = document.getElementById(graph_canvas_id), ctx = canv.getContext("2d"), x, y, canv2 = document.getElementById(text_canvas_id), ctx2 = canv2.getContext("2d"), metrics=null, x0, y0, xmax, ymax;

  //calculations
  graph_w = canvas_w-left_margin-right_margin;
  graph_h = canvas_h-bottom_margin-top_margin;
  
  var ll=points.length

  x0 = xform_point(x_min_value,x_min_value,x_max_value, 0,graph_w,false);
  y0 = xform_point(y_min_value,y_min_value,y_max_value, 0,graph_h,true);
  xmax = xform_point(x_max_value,x_min_value,x_max_value, 0,graph_w,false);
  ymax = xform_point(y_max_value,y_min_value,y_max_value, 0,graph_h,true);
  x=x0;
  y=y0;

  //FC2 color scheme:  blue=00a099 orange=f19000 red=a1185a
  //fill  
  ctx.beginPath();
  ctx.fillStyle = "#f19000"; // orange
  ctx.moveTo(x0,y0);
  for(ii=0;ii<ll;++ii){
    x=xform_point(points[ii][0],x_min_value,x_max_value,0,graph_w,false);
    y=xform_point(points[ii][1],y_min_value,y_max_value,0,graph_h,true);
    ctx.lineTo(x,y);
  }
  ctx.lineTo(xmax,y);
  ctx.lineTo(xmax,y0);
  ctx.fill();
  //line (top only, not right or bottom edges)
  ctx.beginPath();
  ctx.lineWidth=2;
  ctx.strokeStyle="#a1185a"; // red
  ctx.moveTo(x0,y0);
  for(ii=0;ii<ll;++ii){
    x=xform_point(points[ii][0],x_min_value,x_max_value,0,graph_w,false);
    y=xform_point(points[ii][1],y_min_value,y_max_value,0,graph_h,true);
    ctx.lineTo(x,y);
  }
  ctx.lineTo(xmax,y);
  ctx.stroke();
  //text and tick marks on second canvas positioned over the first
  //ctx2.font = '100% Source Sans Pro,Helvetica Neue,Helvetica,Arial,sans-serif'
  //use the same font as the page:
  var fs=window.getComputedStyle(document.getElementById('both'),null).getPropertyValue('font-size');
  var ff=window.getComputedStyle(document.getElementById('both'),null).getPropertyValue('font-family');

  ctx2.font =fs+' '+ff;
  metrics = ctx2.measureText(yLabel);
  ctx2.save();
  ctx2.rotate(-0.5*Math.PI);
  ctx2.fillText(yLabel,-0.5*(metrics.width+graph_h)-top_margin, parseInt(fs,10));

  //bottom tick labels
  var bt,btl,btx;
  if(null != bottomTicks){
    ctx2.font = '16px '+ff;
    for(bt=0;bt<bottomTicks.length;++bt){
      btl = (bottomTicks[bt].length>1) ? (bottomTicks[bt][1]) : '';
      btx = xform_point(bottomTicks[bt][0],x_min_value,x_max_value, 0,xmax,false);
	metrics = ctx2.measureText(btl);
        ctx2.fillText(btl,-1*(graph_h + top_margin + 4)-metrics.width,left_margin+btx+5);
    }
  }
  ctx2.restore();

  //bottom ticks
  ctx.lineWidth=1;
  ctx.strokeStyle="#222222";
  if(null != bottomTicks){
    for(bt=0;bt<bottomTicks.length;++bt){
      btx = xform_point(bottomTicks[bt][0],x_min_value,x_max_value, 0,xmax,false);
      ctx.beginPath();
      ctx.moveTo(btx, graph_h);
      ctx.lineTo(btx, graph_h-4);
      ctx.stroke();
    }
  }

  //bottom label
  metrics=ctx2.measureText(xLabel);
  ctx2.fillText(xLabel, left_margin+graph_w/2-metrics.width/2,canvas_h-4);

  //left ticks and labels
  var lt,ltl,lty;
  if(null != leftTicks){
    ctx2.font = '16px '+ff;
    for(lt=0;lt<leftTicks.length;++lt){
      //label
      ltl = (leftTicks[lt].length>1) ? (leftTicks[lt][1]) : '';
      lty = xform_point(leftTicks[lt][0],y_min_value,y_max_value, 0,graph_h,true);
      metrics = ctx2.measureText(ltl);
      ctx2.fillText(ltl,left_margin-metrics.width-4, top_margin+lty+5);
      //tick
      ctx.beginPath();
      ctx.moveTo(0, lty);
      ctx.lineTo(4, lty);
      ctx.stroke();
    }
  }
}