import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

/// A class describing a restaurant.
class Restaurant {
  const Restaurant({
    required this.id,
    required this.name,
    required this.rating,
  });

  final int id;
  final String name;
  final int rating;
}

const restaurant = [
  Restaurant(
    id: 1,
    name: 'Chinese',
    rating: 4,
  ),
  Restaurant(
    id: 2,
    name: 'Noodles',
    rating: 2,
  ),
  Restaurant(
    id: 3,
    name: 'Italian',
    rating: 1,
  ),
  Restaurant(
    id: 4,
    name: 'French',
    rating: 5,
  ),
  Restaurant(
    id: 5,
    name: 'Indian',
    rating: 4,
  ),
];

/// Provides the list of restaurants.
///
/// Stream provider to simulate fetching data from a server.
final restaurantsProvider =
    StreamProvider.autoDispose<List<Restaurant>>((ref) async* {
  yield restaurant;
});

/// The search value entered by the user.
final searchProvider = StateProvider.autoDispose<String>((ref) {
  return '';
});

/// The selected ratings to filter by
final ratingFilter = StateProvider.autoDispose<Set<int>>((ref) {
  return const {};
});

final filteredRestaurantProvider =
    Provider.autoDispose<AsyncValue<List<Restaurant>>>(
  (ref) {
    final search = ref.watch(searchProvider).toLowerCase();
    final ratings = ref.watch(ratingFilter);
    return ref.watch(restaurantsProvider).whenData(
      (restaurants) {
        return restaurants.where((restaurant) {
          if (ratings.isNotEmpty && !ratings.contains(restaurant.rating)) {
            return false;
          }
          if (search.isNotEmpty &&
              !restaurant.name.toLowerCase().contains(search)) {
            return false;
          }
          return true;
        }).toList();
      },
    );
  },
  dependencies: [
    searchProvider,
    restaurantsProvider,
  ],
);

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      darkTheme: ThemeData.dark(),
      home: const RestaurantsScreen(),
    );
  }
}

/// The screen displaying the list of restaurants.
class RestaurantsScreen extends StatelessWidget {
  const RestaurantsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Restaurants'),
      ),
      body: const Column(
        children: [
          SearchBar(),
          RatingFilter(),
          Expanded(
            child: RestaurantsWidget(),
          ),
        ],
      ),
    );
  }
}

/// Displays the search bar.
class SearchBar extends ConsumerWidget {
  const SearchBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: TextField(
        decoration: const InputDecoration(
          border: OutlineInputBorder(),
          labelText: 'Search',
          hintText: 'Search',
          prefixIcon: Icon(Icons.search),
        ),
        onChanged: (value) {
          ref.read(searchProvider.notifier).state = value;
        },
      ),
    );
  }
}

/// Displays the rating filter.
class RatingFilter extends ConsumerWidget {
  const RatingFilter({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Row(
        children: List.generate(
          6,
          (index) {
            final selected = ref.watch(ratingFilter).contains(index);
            return Expanded(
              child: InputChip(
                selected: selected,
                onPressed: () {
                  final current = {...ref.read(ratingFilter)};
                  if (current.contains(index)) {
                    current.remove(index);
                  } else {
                    current.add(index);
                  }
                  ref.read(ratingFilter.notifier).state = current;
                },
                label: Text(index.toString()),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Displays the list of restaurants.
class RestaurantsWidget extends ConsumerWidget {
  /// Displays the list of restaurants.
  const RestaurantsWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final restaurants = ref.watch(filteredRestaurantProvider);

    if (restaurants.isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }
    return ListView.builder(
      itemCount: restaurants.valueOrNull?.length ?? 0,
      itemBuilder: (context, index) {
        final restaurant = restaurants.valueOrNull![index];
        return ListTile(
          title: Text(restaurant.name),
          subtitle: Text('Rating: ${restaurant.rating}'),
        );
      },
    );
  }
}
