enum AppRoute {
  auth(path: "/auth"),
  login(path: "login"),
  register(path: "register"),
  home(path: "/home/:user_id/:email/:username"),
  createProduct(path: "/product/add"),
  updateProduct(path: "/product/update/:product_id/:product_name/:product_price"),
  landing(path: "/landing"),
  displaySettings(path: "/display-settings"),
  upload(path: "/upload"),
  scanPaste(path: "/scan-paste"),
  lens(path: "/lens"),
  textPad(path: "/text-pad");

  final String path;
  const AppRoute({required this.path});
}
