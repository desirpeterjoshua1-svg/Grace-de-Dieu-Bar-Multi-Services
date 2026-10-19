import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const GraseDeDieuApp());
}

class AppColors {
  static const Color primaryGreen = Color(0xFF0C3823);
  static const Color accentGold = Color(0xFFC99700);
  static const Color background = Color(0xFFF4F6F8);
  static const Color cardBg = Colors.white;
}

class Product {
  final String id;
  final String name;
  final String category;
  final double costPriceHTG;
  final double sellingPriceHTG;
  int stock;
  final int alertThreshold;
  final bool hasCrateOption;
  final int unitsPerCrate;
  final double cratePriceHTG;

  Product({
    required this.id,
    required this.name,
    required this.category,
    required this.costPriceHTG,
    required this.sellingPriceHTG,
    required this.stock,
    this.alertThreshold = 12,
    this.hasCrateOption = false,
    this.unitsPerCrate = 24,
    this.cratePriceHTG = 0.0,
  });

  double get marginHTG => sellingPriceHTG - costPriceHTG;
}

class CartItem {
  final String id;
  final String title;
  final int quantity;
  final double unitPriceHTG;
  final double unitCostHTG;
  final int unitsDeductedFromStock;
  final bool isService;

  CartItem({
    required this.id,
    required this.title,
    required this.quantity,
    required this.unitPriceHTG,
    required this.unitCostHTG,
    required this.unitsDeductedFromStock,
    this.isService = false,
  });

  double get totalHTG => unitPriceHTG * quantity;
  double get profitHTG => (unitPriceHTG - unitCostHTG) * quantity;
}

class SaleRecord {
  final String receiptId;
  final DateTime date;
  final List<CartItem> items;
  final double totalAmountHTG;
  final double profitHTG;
  final String paymentMethod;
  final String cashier;

  SaleRecord({
    required this.receiptId,
    required this.date,
    required this.items,
    required this.totalAmountHTG,
    required this.profitHTG,
    required this.paymentMethod,
    required this.cashier,
  });
}

class GraseDeDieuApp extends StatelessWidget {
  const GraseDeDieuApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Grase de Dieu POS',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: AppColors.primaryGreen,
        scaffoldBackgroundColor: AppColors.background,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primaryGreen,
          primary: AppColors.primaryGreen,
          secondary: AppColors.accentGold,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.primaryGreen,
          foregroundColor: Colors.white,
        ),
        useMaterial3: true,
      ),
      home: const MainHomeScreen(),
    );
  }
}

class MainHomeScreen extends StatefulWidget {
  const MainHomeScreen({super.key});

  @override
  State<MainHomeScreen> createState() => _MainHomeScreenState();
}

class _MainHomeScreenState extends State<MainHomeScreen> {
  int _currentIndex = 0;
  final double _usdRate = 132.50;
  final double _openingFloat = 2500.0;

  final List<Product> _products = [
    Product(id: '1', name: 'Bière Prestige 33cl', category: 'Bières', costPriceHTG: 150, sellingPriceHTG: 200, stock: 96, hasCrateOption: true, cratePriceHTG: 4500),
    Product(id: '2', name: 'Guinness FES 33cl', category: 'Bières', costPriceHTG: 180, sellingPriceHTG: 250, stock: 48, hasCrateOption: true, cratePriceHTG: 5800),
    Product(id: '3', name: 'Rhum Barbancourt', category: 'Spiritueux', costPriceHTG: 1200, sellingPriceHTG: 1600, stock: 10),
    Product(id: '4', name: 'Toro Energy Drink', category: 'Boissons Gazeuses', costPriceHTG: 100, sellingPriceHTG: 150, stock: 50, hasCrateOption: true, cratePriceHTG: 3400),
    Product(id: '5', name: 'Eau Culligan 500ml', category: 'Boissons Gazeuses', costPriceHTG: 40, sellingPriceHTG: 60, stock: 120),
  ];

  final List<CartItem> _cart = [];
  final List<SaleRecord> _salesHistory = [];

  void _addToCart(CartItem item) {
    setState(() {
      final index = _cart.indexWhere((c) => c.id == item.id);
      if (index >= 0) {
        final existing = _cart[index];
        _cart[index] = CartItem(
          id: existing.id,
          title: existing.title,
          quantity: existing.quantity + 1,
          unitPriceHTG: existing.unitPriceHTG,
          unitCostHTG: existing.unitCostHTG,
          unitsDeductedFromStock: existing.unitsDeductedFromStock,
          isService: existing.isService,
        );
      } else {
        _cart.add(item);
      }
    });
  }

  void _clearCart() {
    setState(() => _cart.clear());
  }

  void _processCheckout(String paymentMethod, double amountReceived) {
    double totalHTG = _cart.fold(0, (sum, i) => sum + i.totalHTG);
    double profitHTG = _cart.fold(0, (sum, i) => sum + i.profitHTG);

    for (var item in _cart) {
      if (!item.isService) {
        final prodIndex = _products.indexWhere((p) => p.name == item.title.replaceAll(' (Caisse)', ''));
        if (prodIndex >= 0) {
          _products[prodIndex].stock -= (item.unitsDeductedFromStock * item.quantity);
        }
      }
    }

    final sale = SaleRecord(
      receiptId: 'GD-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
      date: DateTime.now(),
      items: List.from(_cart),
      totalAmountHTG: totalHTG,
      profitHTG: profitHTG,
      paymentMethod: paymentMethod,
      cashier: 'Jean-Baptiste',
    );

    setState(() {
      _salesHistory.add(sale);
      _cart.clear();
    });

    _showReceiptDialog(sale, amountReceived);
  }

  void _showReceiptDialog(SaleRecord sale, double amountReceived) {
    final double change = (amountReceived - sale.totalAmountHTG).clamp(0, double.infinity);
    final fmt = NumberFormat("#,##0.00", "fr_FR");

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Center(
          child: Column(
            children: [
              Text('GRASE DE DIEU', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.primaryGreen)),
              Text('BAR ET MULTI-SERVICES', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              Text('Delmas 33, Haïti • (+509) 3700-0000', style: TextStyle(fontSize: 10, color: Colors.grey)),
              Divider(),
            ],
          ),
        ),
        content: SizedBox(
          width: 320,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Ticket : ${sale.receiptId}', style: const TextStyle(fontWeight: FontWeight.bold)),
              Text('Date : ${DateFormat('dd/MM/yyyy HH:mm').format(sale.date)}'),
              const Divider(),
              ...sale.items.map((i) => Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('${i.quantity}x ${i.title}', style: const TextStyle(fontSize: 12)),
                      Text('${fmt.format(i.totalHTG)} HTG', style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  )),
              const Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('TOTAL :', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  Text('${fmt.format(sale.totalAmountHTG)} HTG', style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.primaryGreen, fontSize: 16)),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Rendu :'),
                  Text('${fmt.format(change)} HTG', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                ],
              ),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryGreen),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK', style: TextStyle(color: Colors.white)),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('GRASE DE DIEU BAR', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _buildPosScreen(),
          _buildMultiServicesScreen(),
          _buildStockScreen(),
          _buildDashboardScreen(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.primaryGreen,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.point_of_sale), label: 'Caisse'),
          BottomNavigationBarItem(icon: Icon(Icons.account_balance_wallet), label: 'Services'),
          BottomNavigationBarItem(icon: Icon(Icons.inventory_2), label: 'Stocks'),
          BottomNavigationBarItem(icon: Icon(Icons.analytics), label: 'Bilan'),
        ],
      ),
    );
  }

  Widget _buildPosScreen() {
    double totalCart = _cart.fold(0, (sum, i) => sum + i.totalHTG);
    return Row(
      children: [
        Expanded(
          flex: 6,
          child: GridView.builder(
            padding: const EdgeInsets.all(8),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 1.1,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: _products.length,
            itemBuilder: (ctx, i) {
              final prod = _products[i];
              return Card(
                color: Colors.white,
                child: InkWell(
                  onTap: prod.stock > 0
                      ? () => _addToCart(CartItem(
                            id: prod.id,
                            title: prod.name,
                            quantity: 1,
                            unitPriceHTG: prod.sellingPriceHTG,
                            unitCostHTG: prod.costPriceHTG,
                            unitsDeductedFromStock: 1,
                          ))
                      : null,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${prod.stock} disp.', style: const TextStyle(fontSize: 10, color: Colors.green, fontWeight: FontWeight.bold)),
                        const Spacer(),
                        Text(prod.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        Text('${prod.sellingPriceHTG.toStringAsFixed(0)} HTG', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryGreen)),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        Expanded(
          flex: 4,
          child: Container(
            color: Colors.white,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  color: AppColors.primaryGreen,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Panier', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      IconButton(icon: const Icon(Icons.delete, color: Colors.white, size: 18), onPressed: _clearCart),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: _cart.length,
                    itemBuilder: (ctx, i) => ListTile(
                      dense: true,
                      title: Text(_cart[i].title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                      trailing: Text('${_cart[i].totalHTG.toStringAsFixed(0)} HTG'),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryGreen),
                    onPressed: _cart.isEmpty ? null : () => _processCheckout('Espèces HTG', totalCart),
                    child: Text('Payer (${totalCart.toStringAsFixed(0)} HTG)', style: const TextStyle(color: Colors.white)),
                  ),
                )
              ],
            ),
          ),
        )
      ],
    );
  }

  Widget _buildMultiServicesScreen() {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        ListTile(
          tileColor: Colors.white,
          leading: const Icon(Icons.print, color: AppColors.primaryGreen),
          title: const Text('Photocopie / Impression'),
          subtitle: const Text('10 HTG'),
          trailing: const Icon(Icons.add),
          onTap: () {
            _addToCart(CartItem(
              id: 'srv_${DateTime.now().millisecondsSinceEpoch}',
              title: 'Photocopie',
              quantity: 1,
              unitPriceHTG: 10,
              unitCostHTG: 3,
              unitsDeductedFromStock: 0,
              isService: true,
            ));
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Photocopie ajoutée au panier !')));
          },
        ),
      ],
    );
  }

  Widget _buildStockScreen() {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _products.length,
      itemBuilder: (ctx, i) => Card(
        child: ListTile(
          title: Text(_products[i].name, style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text('Stock : ${_products[i].stock} bouteilles'),
        ),
      ),
    );
  }

  Widget _buildDashboardScreen() {
    double totalRevenue = _salesHistory.fold(0, (sum, s) => sum + s.totalAmountHTG);
    double totalProfit = _salesHistory.fold(0, (sum, s) => sum + s.profitHTG);
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Card(
            child: ListTile(
              title: const Text('Recettes Totales'),
              trailing: Text('${totalRevenue.toStringAsFixed(2)} HTG', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ),
          Card(
            child: ListTile(
              title: const Text('Bénéfice Réel Estimé'),
              trailing: Text('${totalProfit.toStringAsFixed(2)} HTG', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.green)),
            ),
          ),
        ],
      ),
    );
  }
}
