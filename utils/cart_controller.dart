import 'package:get/get.dart';

class CartController extends GetxController {
  var total = 0.obs;
  var ItemLength = new Map().obs;
  var ItemPrice = new Map().obs;
  List currItems = [].obs;
  List kitchen = [];
  late Map<String, int> freq;
  void increment(int ind, int price, String name) {
    total.value += price;

    currItems.add(name);

    if (ItemLength.containsKey(name)) {
      ItemPrice[price] += 1;
      ItemLength[name] += 1;
    } else {
      ItemPrice[price] = 1;
      ItemLength[name] = 1;
    }
    print(ItemPrice);
  }

  void decrement(int ind, int price, String name) {
    total.value -= price;
    ItemLength[name]--;
    ItemPrice[price]--;
    currItems.removeLast();
  }
}
