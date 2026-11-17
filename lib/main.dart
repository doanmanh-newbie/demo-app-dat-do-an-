// Flutter Apprentice - Chương 7: bản demo khớp với slide "5 chi tiết khiến người dùng thích".
//
// Các phần trong file (khớp với slide):
//   - Slide 3: showModalBottomSheet + showDragHandle + useSafeArea  -> _openDetails
//   - Slide 4: DraggableScrollableSheet (chọn topping)               -> ToppingsSheet
//   - Slide 5: trang con báo (onAdd), trang cha làm (cart.add)       -> ItemDetails.onAdd
//   - Slide 6: Badge + ListenableBuilder trên nút giỏ hàng           -> _CartButton
//   - Slide 7: Dismissible vuốt sang trái để xóa                     -> CartPage
//   - Slide 8: SnackBar có nút HOÀN TÁC                              -> CartPage
//   - Slide 9: ô chạm 48dp, HapticFeedback, context.mounted, dispose
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() => runApp(const YummyApp());

// ---------------------------------------------------------------------------
// MÀU + ĐỊNH DẠNG (lấy từ bảng màu của slide)
// ---------------------------------------------------------------------------

const _cream = Color(0xFFFFF7ED);
const _ink = Color(0xFF1C1917);
const _grey = Color(0xFF78716C);
const _orange = Color(0xFFF97316);
const _orangeDark = Color(0xFFEA580C);
const _orangeSoft = Color(0xFFFED7AA);
const _orangeLight = Color(0xFFFDBA74);

/// 65000 -> "65.000đ"
String vnd(int v) =>
    '${v.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => '.')}đ';

// ---------------------------------------------------------------------------
// MODEL
// ---------------------------------------------------------------------------

class Item {
  final String name, description, emoji, category, time;
  final int price;
  final double rating;
  final Color tint;

  const Item({
    required this.name,
    required this.description,
    required this.emoji,
    required this.category,
    required this.price,
    required this.tint,
    this.rating = 4.8,
    this.time = '15 phút',
  });
}

const _menu = [
  Item(
    name: 'Phở bò tái',
    description: 'Nước dùng hầm xương 12 tiếng, thịt bò tái mềm, hành chần và rau thơm.',
    emoji: '🍜',
    category: 'Món nước',
    price: 65000,
    tint: Color(0xFFFFEBD2),
  ),
  Item(
    name: 'Cơm tấm sườn',
    description: 'Sườn nướng than, bì, chả trứng và mỡ hành, ăn kèm nước mắm chua ngọt.',
    emoji: '🍚',
    category: 'Cơm',
    price: 55000,
    tint: Color(0xFFFEF3C7),
    rating: 4.7,
    time: '20 phút',
  ),
  Item(
    name: 'Gỏi cuốn',
    description: 'Tôm, thịt, bún và rau sống cuốn bánh tráng, chấm tương đậu phộng.',
    emoji: '🥗',
    category: 'Khác',
    price: 40000,
    tint: Color(0xFFDCFCE7),
    rating: 4.6,
    time: '10 phút',
  ),
  Item(
    name: 'Trà sữa',
    description: 'Trà đen thơm, sữa béo, trân châu đen dai mềm nấu mỗi ngày.',
    emoji: '🧋',
    category: 'Đồ uống',
    price: 35000,
    tint: Color(0xFFDFF0FC),
    rating: 4.9,
    time: '8 phút',
  ),
];

class Topping {
  final String name, emoji;
  final int price;
  const Topping(this.name, this.emoji, this.price);
}

const _toppings = [
  Topping('Thêm tái nạm', '🥩', 15000),
  Topping('Trứng chần', '🥚', 8000),
  Topping('Thêm rau thơm', '🌿', 0),
  Topping('Ớt sa tế', '🌶️', 0),
  Topping('Chanh tươi', '🍋', 0),
  Topping('Quẩy giòn', '🥖', 5000),
  Topping('Hành phi', '🧅', 0),
];

class CartItem {
  final String id, name, emoji;
  final int price, quantity; // price = đơn giá đã cộng topping

  const CartItem({
    required this.id,
    required this.name,
    required this.emoji,
    required this.price,
    required this.quantity,
  });
}

/// Giỏ hàng là ChangeNotifier: đổi giỏ thì chỉ ListenableBuilder phía dưới vẽ lại.
class Cart extends ChangeNotifier {
  final List<CartItem> _items = [];

  List<CartItem> get items => List.unmodifiable(_items);
  int get count => _items.length;
  int get total => _items.fold(0, (s, i) => s + i.price * i.quantity);

  void add(CartItem item) {
    _items.add(item);
    notifyListeners();
  }

  void remove(CartItem item) {
    _items.remove(item);
    notifyListeners();
  }

  // Dùng cho nút HOÀN TÁC: chèn món lại đúng vị trí cũ.
  void insert(int index, CartItem item) {
    _items.insert(index.clamp(0, _items.length), item);
    notifyListeners();
  }
}

// ---------------------------------------------------------------------------
// APP
// ---------------------------------------------------------------------------

class YummyApp extends StatelessWidget {
  const YummyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bếp Nhà Mình',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: _orange,
        scaffoldBackgroundColor: _cream,
        snackBarTheme: SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          backgroundColor: _ink,
          contentTextStyle: const TextStyle(color: Colors.white, fontSize: 15),
          actionTextColor: _orangeLight,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
      home: const MenuPage(),
    );
  }
}

// ---------------------------------------------------------------------------
// MENU PAGE (slide 3, 6)
// ---------------------------------------------------------------------------

class MenuPage extends StatefulWidget {
  const MenuPage({super.key});

  @override
  State<MenuPage> createState() => _MenuPageState();
}

class _MenuPageState extends State<MenuPage> {
  static const _categories = ['Tất cả', 'Món nước', 'Cơm', 'Đồ uống'];
  final Cart cart = Cart();
  String _category = 'Tất cả';
  int _idCounter = 0;

  // Slide 3: tờ giấy trượt từ dưới lên.
  void _openDetails(Item item) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true, // thanh xám nhỏ gợi ý "kéo xuống được"
      useSafeArea: true,
      backgroundColor: Colors.white,
      constraints: const BoxConstraints(maxWidth: 480),
      builder: (_) => ItemDetails(
        item: item,
        // Slide 5: trang con chỉ báo, trang cha là nơi sửa giỏ hàng.
        onAdd: (quantity, unitPrice) => cart.add(CartItem(
          id: '${DateTime.now().microsecondsSinceEpoch}-${_idCounter++}',
          name: item.name,
          emoji: item.emoji,
          price: unitPrice,
          quantity: quantity,
        )),
      ),
    );
  }

  void _openCart() {
    Navigator.push(
      context,
      MaterialPageRoute<void>(builder: (_) => CartPage(cart: cart)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final shown = _category == 'Tất cả'
        ? _menu
        : _menu.where((i) => i.category == _category).toList();

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Giao đến Quận 1',
                                style: TextStyle(color: _grey, fontSize: 15)),
                            Text('Bếp Nhà Mình',
                                style: TextStyle(
                                    color: _ink,
                                    fontSize: 32,
                                    fontWeight: FontWeight.w900)),
                          ],
                        ),
                      ),
                      _CartButton(cart: cart, onTap: _openCart),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 44,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: _categories.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 8),
                    itemBuilder: (_, i) {
                      final c = _categories[i];
                      final selected = c == _category;
                      return ChoiceChip(
                        label: Text(c),
                        selected: selected,
                        showCheckmark: false,
                        onSelected: (_) => setState(() => _category = c),
                        backgroundColor: Colors.white,
                        selectedColor: _ink,
                        side: BorderSide.none,
                        shape: const StadiumBorder(),
                        labelStyle: TextStyle(
                          color: selected ? Colors.white : const Color(0xFF57534E),
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      );
                    },
                  ),
                ),
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.all(20),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      childAspectRatio: 0.88,
                    ),
                    itemCount: shown.length,
                    itemBuilder: (_, i) => _MenuCard(
                      item: shown[i],
                      onTap: () => _openDetails(shown[i]),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MenuCard extends StatelessWidget {
  final Item item;
  final VoidCallback onTap;
  const _MenuCard({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(28),
      elevation: 2,
      shadowColor: _orangeLight.withValues(alpha: 0.4),
      child: InkWell(
        borderRadius: BorderRadius.circular(28),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Container(
                  width: double.infinity,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: item.tint,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(item.emoji, style: const TextStyle(fontSize: 64)),
                ),
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: _ink, fontSize: 17, fontWeight: FontWeight.w700)),
                    Text(vnd(item.price),
                        style: const TextStyle(
                            color: _orangeDark,
                            fontSize: 16,
                            fontWeight: FontWeight.w800)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Slide 6: chấm số trên giỏ hàng, ẩn khi giỏ trống.
class _CartButton extends StatelessWidget {
  final Cart cart;
  final VoidCallback onTap;
  const _CartButton({required this.cart, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Giỏ hàng',
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        elevation: 3,
        shadowColor: _orangeLight.withValues(alpha: 0.5),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: SizedBox(
            width: 52, // lớn hơn 48 để dễ chạm
            height: 52,
            child: ListenableBuilder(
              listenable: cart,
              builder: (context, _) => Badge(
                label: Text('${cart.count}'),
                isLabelVisible: cart.count > 0,
                backgroundColor: _orange,
                textColor: Colors.white,
                child: const Icon(Icons.shopping_cart_outlined, color: _ink, size: 26),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// ITEM DETAILS: nội dung tờ giấy trượt lên (slide 3, 5)
// ---------------------------------------------------------------------------

class ItemDetails extends StatefulWidget {
  final Item item;
  // Slide 5: callback đi LÊN (số lượng, đơn giá đã gồm topping).
  final void Function(int quantity, int unitPrice) onAdd;

  const ItemDetails({super.key, required this.item, required this.onAdd});

  @override
  State<ItemDetails> createState() => _ItemDetailsState();
}

class _ItemDetailsState extends State<ItemDetails> {
  int _quantity = 1;
  Set<int> _picked = {};

  int get _unitPrice =>
      widget.item.price + _picked.fold(0, (s, i) => s + _toppings[i].price);

  // Slide 4: tờ giấy topping kéo được nhiều mức.
  Future<void> _pickToppings() async {
    final result = await showModalBottomSheet<Set<int>>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      constraints: const BoxConstraints(maxWidth: 480),
      builder: (_) => ToppingsSheet(initial: _picked),
    );
    // Slide 9: sau await, trang có thể đã đóng -> kiểm tra mounted.
    if (!mounted || result == null) return;
    setState(() => _picked = result);
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 190,
            width: double.infinity,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              gradient: const LinearGradient(
                colors: [_orangeSoft, _orangeLight],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Text(item.emoji, style: const TextStyle(fontSize: 96)),
          ),
          const SizedBox(height: 16),
          Text(item.name,
              style: const TextStyle(
                  color: _ink, fontSize: 28, fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          Row(children: [
            _Pill('⭐ ${item.rating.toString().replaceAll('.', ',')}'),
            const SizedBox(width: 8),
            _Pill('🕒 ${item.time}'),
          ]),
          const SizedBox(height: 10),
          Text(item.description,
              style: const TextStyle(color: _grey, fontSize: 16, height: 1.4)),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: _pickToppings,
            icon: const Icon(Icons.add_circle_outline),
            label: Text(_picked.isEmpty
                ? 'Chọn thêm topping'
                : 'Đã chọn ${_picked.length} topping'),
            style: TextButton.styleFrom(
              foregroundColor: _orangeDark,
              minimumSize: const Size(48, 48),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(vnd(_unitPrice),
                    style: const TextStyle(
                        color: _orangeDark,
                        fontSize: 30,
                        fontWeight: FontWeight.w900)),
              ),
              _Stepper(
                value: _quantity,
                onChanged: (v) => setState(() => _quantity = v),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 58,
            child: FilledButton(
              onPressed: () {
                HapticFeedback.lightImpact(); // slide 9: rung nhẹ khi thêm món
                widget.onAdd(_quantity, _unitPrice);
                Navigator.pop(context);
              },
              style: FilledButton.styleFrom(
                backgroundColor: _orange,
                shape: const StadiumBorder(),
                textStyle:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
              child: Text('Thêm vào giỏ · ${vnd(_unitPrice * _quantity)}'),
            ),
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String text;
  const _Pill(this.text);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFE8FAF0),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(text,
          style: const TextStyle(
              color: Color(0xFF047857), fontWeight: FontWeight.w700)),
    );
  }
}

/// Nút − 1 + (StatefulWidget cha giữ số, ở đây chỉ vẽ và báo lên).
class _Stepper extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;
  const _Stepper({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: _cream,
        borderRadius: BorderRadius.circular(32),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton.filled(
            tooltip: 'Giảm số lượng',
            onPressed: value > 1 ? () => onChanged(value - 1) : null,
            icon: const Icon(Icons.remove),
            style: IconButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: _ink,
              minimumSize: const Size(48, 48),
            ),
          ),
          SizedBox(
            width: 40,
            child: Text('$value',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
          ),
          IconButton.filled(
            tooltip: 'Tăng số lượng',
            onPressed: () => onChanged(value + 1),
            icon: const Icon(Icons.add),
            style: IconButton.styleFrom(
              backgroundColor: _orange,
              foregroundColor: Colors.white,
              minimumSize: const Size(48, 48),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// TOPPINGS SHEET: DraggableScrollableSheet (slide 4)
// ---------------------------------------------------------------------------

class ToppingsSheet extends StatefulWidget {
  final Set<int> initial;
  const ToppingsSheet({super.key, required this.initial});

  @override
  State<ToppingsSheet> createState() => _ToppingsSheetState();
}

class _ToppingsSheetState extends State<ToppingsSheet> {
  late final Set<int> _picked = {...widget.initial};

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.4,
      minChildSize: 0.25,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, controller) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Stack(
            children: [
              // Phải dùng đúng `controller` Flutter đưa cho, nếu không danh sách
              // và tờ giấy sẽ giành nhau khi vuốt.
              ListView(
                controller: controller,
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 100),
                children: [
                  const SizedBox(height: 12),
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFFD6D3D1),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('Chọn thêm topping',
                      style: TextStyle(
                          color: _ink, fontSize: 26, fontWeight: FontWeight.w900)),
                  const Text('Kéo lên để xem hết, kéo xuống để thu nhỏ',
                      style: TextStyle(color: _grey, fontSize: 15)),
                  const SizedBox(height: 8),
                  for (var i = 0; i < _toppings.length; i++) _row(i),
                ],
              ),
              Positioned(
                left: 24,
                right: 24,
                bottom: 20,
                height: 58,
                child: FilledButton(
                  onPressed: () => Navigator.pop(context, _picked),
                  style: FilledButton.styleFrom(
                    backgroundColor: _orange,
                    shape: const StadiumBorder(),
                    textStyle:
                        const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                  child: Text('Xong · ${_picked.length} topping'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _row(int i) {
    final t = _toppings[i];
    final on = _picked.contains(i);
    return InkWell(
      onTap: () => setState(() => on ? _picked.remove(i) : _picked.add(i)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: const Color(0xFFFFEBD2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(t.emoji, style: const TextStyle(fontSize: 28)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(t.name,
                      style: const TextStyle(
                          color: _ink, fontSize: 17, fontWeight: FontWeight.w700)),
                  Text(t.price == 0 ? 'Miễn phí' : '+${vnd(t.price)}',
                      style: const TextStyle(color: _grey, fontSize: 15)),
                ],
              ),
            ),
            Icon(on ? Icons.check_circle : Icons.radio_button_unchecked,
                color: on ? _orange : _ink),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// CART PAGE: Dismissible + SnackBar HOÀN TÁC (slide 7, 8)
// ---------------------------------------------------------------------------

class CartPage extends StatelessWidget {
  final Cart cart;
  const CartPage({super.key, required this.cart});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: ListenableBuilder(
              listenable: cart,
              builder: (context, _) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8, 8, 20, 0),
                    child: Row(
                      children: [
                        IconButton(
                          tooltip: 'Quay lại',
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.arrow_back, color: _ink),
                        ),
                        Text('${cart.count} món',
                            style: const TextStyle(color: _grey, fontSize: 15)),
                      ],
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Text('Giỏ hàng',
                        style: TextStyle(
                            color: _ink, fontSize: 32, fontWeight: FontWeight.w900)),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: cart.count == 0
                        ? const Center(
                            child: Text('Giỏ hàng đang trống 🛒',
                                style: TextStyle(color: _grey, fontSize: 17)))
                        : ListView.separated(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            itemCount: cart.count,
                            separatorBuilder: (_, _) => const SizedBox(height: 12),
                            itemBuilder: (context, index) =>
                                _tile(context, cart.items[index], index),
                          ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 24, vertical: 22),
                      decoration: BoxDecoration(
                        color: _ink,
                        borderRadius: BorderRadius.circular(28),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Tổng cộng',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800)),
                          Text(vnd(cart.total),
                              style: const TextStyle(
                                  color: _orangeLight,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _tile(BuildContext context, CartItem item, int index) {
    return Dismissible(
      key: ValueKey(item.id), // mỗi món một mã riêng
      direction: DismissDirection.endToStart, // vuốt sang trái
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 28),
        decoration: BoxDecoration(
          color: const Color(0xFFDC2626),
          borderRadius: BorderRadius.circular(28),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.delete, color: Colors.white),
            SizedBox(width: 8),
            Text('Xóa',
                style: TextStyle(
                    color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800)),
          ],
        ),
      ),
      onDismissed: (_) {
        cart.remove(item);
        // Slide 8: không hỏi "bạn có chắc không?", cho xóa luôn rồi cho hoàn tác.
        ScaffoldMessenger.of(context)
          ..clearSnackBars()
          ..showSnackBar(SnackBar(
            content: Text('Đã xóa ${item.name}'),
            action: SnackBarAction(
              label: 'HOÀN TÁC',
              onPressed: () => cart.insert(index, item),
            ),
          ));
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: const Color(0xFFFFEBD2),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Text(item.emoji, style: const TextStyle(fontSize: 32)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.name,
                      style: const TextStyle(
                          color: _ink, fontSize: 17, fontWeight: FontWeight.w800)),
                  Text('Số lượng: ${item.quantity}',
                      style: const TextStyle(color: _grey, fontSize: 15)),
                ],
              ),
            ),
            Text(vnd(item.price * item.quantity),
                style: const TextStyle(
                    color: _ink, fontSize: 17, fontWeight: FontWeight.w800)),
            const SizedBox(width: 6),
          ],
        ),
      ),
    );
  }
}
