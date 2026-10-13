import '../models/bucket_item.dart';

/// The original Drive list, loaded the first time the app opens.
List<BucketItem> buildSeedItems() {
  final base = DateTime(2022, 1, 1);
  var index = 0;

  BucketItem item(
    BucketCategory category,
    String title, {
    String note = '',
    String location = '',
    List<String> links = const [],
  }) {
    final i = index++;
    return BucketItem(
      id: 'seed-$i',
      category: category,
      title: title,
      note: note,
      location: location,
      links: links,
      // Earlier entries get later dates so the original order is kept
      // when sorting newest first.
      createdAt: base.subtract(Duration(minutes: i)),
    );
  }

  const r = BucketCategory.restaurantes;
  const v = BucketCategory.viajes;
  const p = BucketCategory.planes;
  const s = BucketCategory.series;

  return [
    item(
      r,
      'Cosaica',
      note: 'Familias',
      location: 'Vía Suba-Cota km 27, vía Chía-Cajicá',
    ),
    item(
      r,
      'Papas tóxicas',
      note: 'Hamburguesita · Febrero 12 comida',
      location: 'Calle 71 # 9-67',
    ),
    item(
      r,
      'Restaurante en Ibagué',
      note: 'Preguntarle a Duarte · Agosto 2022',
      location: 'Ibagué',
    ),
    item(r, 'Kyqa Mhuysqa', note: 'Familia', location: 'Facatativá'),
    item(
      r,
      'No me acuerdo el nombre',
      note: 'Familias',
      location: 'Vía La Vega',
    ),
    item(r, 'La Galleta', note: 'Enero 2023', location: 'Villa de Leyva'),
    item(r, 'Fiorella', note: 'Cada 15'),
    item(r, 'La Lonchera', note: 'Cada 15'),
    item(r, 'Mila Gastropub', note: 'Marzo 19'),
    item(r, 'Criterion', note: 'No sabemos'),
    item(r, 'La Apuesta', note: 'No sabemos', location: 'Multiplaza'),
    item(r, 'Don Benítez', note: 'Domingo 4'),
    item(r, 'La Industria', location: 'Miami'),
    item(r, 'Cake Boss', location: 'New York'),
    item(r, 'Al lado de la pizza', note: 'Junio 10'),
    item(r, 'Rosarito', note: 'Mayo 7-8'),
    item(r, 'Fasfu Burguer', note: 'Junio'),
    item(r, 'MilkShake'),
    item(r, 'Hacer cóctel'),
    item(r, 'Kion'),
    item(
      r,
      'El Canto del Mar',
      location: 'Calle 62 Carrera 6a esquina, Prados del Norte, Ibagué, Tolima',
    ),
    item(r, 'Señor Law', location: 'Cra 4 #11-14, Ibagué, Tolima'),
    item(r, 'Makibar'),
    item(r, 'Reina'),
    item(
      r,
      'Heroes Burger Bogotá',
      links: ['https://www.instagram.com/heroesburgerbogota'],
    ),
    item(
      r,
      'Nientiendo Restobar',
      links: ['https://www.instagram.com/nientiendo_restobar'],
    ),
    item(r, 'Con B de Burro'),
    item(r, 'Chef Burger', note: 'Nuestro Bogotá'),
    item(r, 'Patacón Bay'),

    item(v, 'Casa Morales', note: 'Pasadía 60.000'),
    item(v, 'Palace New York', location: 'New York'),
    item(v, 'Grecia', location: 'Atenas'),
    item(v, 'Pueblito Boyacense', note: 'Familias'),
    item(v, 'Ibagué'),
    item(v, 'Granada, Meta', note: 'Marzo'),
    item(v, 'Recorrido en bote', location: 'Cartagena'),
    item(v, 'Hospedaje para parejas Solarium', location: 'Cartagena'),
    item(v, 'Mundo Aventura', note: 'Septiembre'),
    item(v, 'Salitre Mágico', note: 'Septiembre'),
    item(v, 'Dosis Verde, casa del árbol', note: 'Familias'),
    item(v, 'Saccharum', note: 'Cabañas privadas', location: 'Nocaima'),
    item(v, 'Macadamia'),
    item(v, 'Hotel Los Recuerdos', location: 'Guatapé'),
    item(
      v,
      'Glamping Refugio JD',
      links: ['https://www.instagram.com/glampingrefugiojd'],
    ),
    item(v, 'Hungría'),
    item(v, 'Letonia'),
    item(v, 'Bulgaria'),
    item(v, 'Turquía'),
    item(v, 'Rumania'),
    item(v, 'Tiny house Serendipia'),
    item(
      v,
      'Playa Surf',
      location: 'Isla Barú',
      links: ['https://www.instagram.com/playasurf_islabaru'],
    ),

    item(p, 'Morbius', note: 'Marzo'),
    item(p, 'Ir de compras', note: 'Junio'),
    item(p, '4-18', note: 'Febrero'),
    item(
      p,
      'Recrearte',
      links: [
        'https://www.instagram.com/passportmarks/reel/CX9UN5DPS9X/?utm_medium=share_sheet',
        'https://www.instagram.com/reel/CXoHSlLFD2z/?utm_medium=share_sheet',
      ],
    ),
    item(p, 'Pescar cerca a La Vega', location: 'La Vega'),
    item(p, '104 Art Suites', location: 'Bogotá'),

    item(s, 'Gossip Girl'),
    item(s, 'The Witcher'),
    item(s, 'What If...?'),
    item(s, 'Falcon and the Winter Soldier'),
    item(s, 'Loki'),
    item(s, 'Boy Meets World'),
  ];
}
