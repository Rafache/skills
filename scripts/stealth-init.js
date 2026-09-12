delete Object.getPrototypeOf(navigator).webdriver;
const cleanUa = navigator.userAgent.replace('HeadlessChrome', 'Chrome');
Object.defineProperty(navigator, 'userAgent', { get: () => cleanUa });
const hook = (proto) => {
  if (!proto || !proto.getParameter) return;
  const orig = proto.getParameter;
  proto.getParameter = function(p) {
    if (p === 37445) return 'Google Inc. (AMD)';
    if (p === 37446) return 'ANGLE (AMD, AMD Radeon 780M, OpenGL 4.6)';
    return orig.apply(this, arguments);
  };
};
if (typeof WebGLRenderingContext !== 'undefined') hook(WebGLRenderingContext.prototype);
if (typeof WebGL2RenderingContext !== 'undefined') hook(WebGL2RenderingContext.prototype);
