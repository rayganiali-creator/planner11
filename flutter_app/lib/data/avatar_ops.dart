// وضعیتِ آواتار: جنسیت، کمد (owned)، پوشیده‌ها (equipped)، خرید با سکه و پوشیدن. قواعدِ نسخه‌ی HTML.
import '../features/avatar/avatar_compose.dart';
import 'actions.dart';

class AvCategory {
  final String key, fa, en, icon;
  final int price;
  final bool hidden;
  const AvCategory(this.key, this.fa, this.en, this.icon, this.price, {this.hidden = false});
}

const avCategories = [
  AvCategory('body', 'مدل', 'Model', '🧑', 0),
  AvCategory('clothes', 'لباس', 'Clothes', '👕', 800),
  AvCategory('shoes', 'کفش', 'Shoes', '👟', 800, hidden: true),
  AvCategory('hair', 'مو', 'Hair', '💇', 400),
  AvCategory('hat', 'کلاه', 'Hats', '🧢', 400),
  AvCategory('hijab', 'روسری', 'Hijab', '🧕', 400),
  AvCategory('armor', 'زره', 'Armor', '🦺', 1000),
  AvCategory('cape', 'شنل', 'Capes', '🧥', 1000),
  AvCategory('sword', 'سلاح', 'Weapons', '🗡️', 1100),
  AvCategory('helmet', 'کلاه‌خود', 'Helmets', '⛑️', 1300),
  AvCategory('shield', 'سپر', 'Shields', '🛡️', 1000),
  AvCategory('pet', 'حیوان', 'Pets', '🐾', 800),
  AvCategory('petgear', 'لوازم حیوان', 'Pet Gear', '🎀', 400),
];

class AvatarState {
  final Map a;
  AvatarState(this.a);
  String? get gender => a['gender'] as String?;
  Map get owned => a['owned'] as Map;
  Map equippedOf(String g) => (a['equipped'] as Map)[g] as Map;
}

extension AvatarOps on AppActions {
  String? get avStateGender => avState().gender;

  AvatarState avState() {
    final s = store.state;
    if (s['avatar'] is! Map) s['avatar'] = <String, dynamic>{};
    final a = s['avatar'] as Map;
    if (a['owned'] is! Map || a['owned'] == null) a['owned'] = <String, dynamic>{};
    if (a['equipped'] is! Map) a['equipped'] = <String, dynamic>{'male': <String, dynamic>{}, 'female': <String, dynamic>{}};
    final eq = a['equipped'] as Map;
    if (eq['male'] is! Map) eq['male'] = <String, dynamic>{};
    if (eq['female'] is! Map) eq['female'] = <String, dynamic>{};
    // نسخه‌های قدیمی همه‌ی لوازم حیوان را در یک جایگاه می‌گذاشتند → به جایگاهِ سر/گردن منتقل می‌شود
    return AvatarState(a);
  }

  void migratePetGear(AvData data) {
    final st = avState();
    for (final g in ['male', 'female']) {
      final eq = st.equippedOf(g);
      if (!eq.containsKey('petgear')) continue;
      final it = data.items['${eq['petgear']}'];
      if (it != null && eq[it.slot] == null) eq[it.slot] = eq['petgear'];
      eq.remove('petgear');
    }
  }

  bool avOwned(AvData data, String id) => avState().owned[id] == true || (data.items[id]?.price == 0);

  String baseIdFor(AvData data, String g) {
    final b = avState().equippedOf(g)['base'];
    return (b != null && data.items['$b']?.gender == g) ? '$b' : (g == 'male' ? 'base/male' : 'base/female');
  }

  void chooseGender(String g) {
    avState().a['gender'] = g;
    store.save();
    toasts.show(store.state['lang'] != 'en' ? '✨ آواتار شما ساخته شد! برای شخصی‌سازی روی آن بزنید.' : '✨ Your avatar is ready! Tap it to customize.', ms: 3000);
  }

  void switchGender(String g) {
    final st = avState();
    if (st.gender == g) return;
    st.a['gender'] = g;
    store.save();
  }

  void avEquip(AvData data, AvItem it) {
    final st = avState();
    final g = st.gender!;
    if (!it.compatible(g) || !avOwned(data, it.id)) return;
    final eq = st.equippedOf(g);
    eq[it.slot] = it.id;
    if (it.kind == 'outfit') eq.remove('pants');
    if (it.kind == 'pants' && eq['clothes'] != null && data.items['${eq['clothes']}']?.kind == 'outfit') eq.remove('clothes');
  }

  /// نتیجه‌ی عملِ دکمه‌ی پایین برگه: 'pro' | 'unequipped' | 'equipped' | 'armed' | 'bought' | 'nocoins' | 'none'
  String avAction(AvData data, AvItem it, {required bool armed}) {
    final pro = store.state['isPremium'] == true;
    if (it.price > 0 && !pro) return 'pro';
    final st = avState();
    final g = st.gender!;
    final eq = st.equippedOf(g);
    if (!it.compatible(g)) return 'none';
    if (it.kind == 'base') {
      eq['base'] = it.id;
      store.save();
      return 'equipped';
    }
    if (eq[it.slot] == it.id) {
      eq.remove(it.slot);
      store.save();
      return 'unequipped';
    }
    if (avOwned(data, it.id)) {
      avEquip(data, it);
      store.save();
      return 'equipped';
    }
    if (!armed) return 'armed';
    if (!spendCoins(it.price)) return 'nocoins';
    st.owned[it.id] = true;
    avEquip(data, it);
    final fa = store.state['lang'] != 'en';
    toasts.show(fa ? '🛍️ «${it.name}» خریداری شد و پوشیده شد.' : '🛍️ Bought and equipped!', ms: 2400, cls: 'toast-success');
    store.save();
    return 'bought';
  }

  /// خرجِ سکه در فروشگاه (جدا از سقف ۵۰تایی پاداش‌ها)
  bool spendCoins(num amount) {
    final a = amount.isFinite ? amount.round().clamp(0, 1 << 31) : 0;
    final sc = store.state['scores'] as Map;
    final have = ((sc['coins'] as num?) ?? 0);
    if (have < a) return false;
    sc['coins'] = have - a;
    return true;
  }
}
