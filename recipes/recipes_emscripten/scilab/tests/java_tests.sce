// Run by test_scilab.sh with run_headless.js: the program of the web page
// (Scilab with OpenJDK 21) under node, with headless Java.
mode(-1);
function ok(name)
    mprintf("ok: %s\n", name);
endfunction

// Java through JIMS
jimport java.lang.System;
v = System.getProperty("os.name");
assert_checktrue(length(v) > 0);
ok("java (os.name: " + v + ")");

// graphics: the figures are drawn by SciRenderer's Java2D renderer
plot3d();
xs2png(gcf(), TMPDIR + "/plot3d.png");
assert_checktrue(isfile(TMPDIR + "/plot3d.png"));
clf();
plot2d();
xstring(0, 0, "$\int_0^1 x\,dx$");
xs2svg(gcf(), TMPDIR + "/plot2d.svg");
assert_checktrue(isfile(TMPDIR + "/plot2d.svg"));
xs2pdf(gcf(), TMPDIR + "/plot2d.pdf");
assert_checktrue(isfile(TMPDIR + "/plot2d.pdf"));
delete(gcf());
ok("graphics");

// Xcos: a demo diagram, loaded by the Java side and simulated
loadXcosLibs();
loadScicos();
assert_checktrue(importXcosDiagram(SCI + "/modules/xcos/demos/Simple_Demo.zcos"));
scs_m.props.tf = 5;
Info = scicos_simulate(scs_m, list(), "nw");
ok("xcos");

mprintf("ALL TESTS PASSED\n");
