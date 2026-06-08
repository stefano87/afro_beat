import '../config/app_config.dart';
import '../models/radio_station.dart';

/// Mock afrobeat / afro trap radio stations for development preview.
const List<RadioStation> radioStations = [
  RadioStation(
    id: 1,
    name: 'bigFM Afrobeats',
    description: 'The hottest Afrobeats, Dancehall & Reggae vibes',
    genre: 'Afrobeats',
    url: 'https://stream.bigfm.de/dancehall/mp3-128/radio-browser',
    artwork: AppConfig.logoAsset,
  ),
  RadioStation(
    id: 2,
    name: 'AfroBeats FM',
    description: "Africa's #1 Afrobeat music radio station",
    genre: 'Afrobeats',
    url: 'https://stream.zeno.fm/0r0xa792kwzuv',
    artwork: AppConfig.logoAsset,
  ),
  RadioStation(
    id: 3,
    name: 'Amapiano Mix',
    description: 'Non-stop Amapiano & Afro house selections',
    genre: 'Amapiano',
    url: 'https://eu10.fastcast4u.com:17870/;',
    artwork: AppConfig.logoAsset,
  ),
  RadioStation(
    id: 4,
    name: 'Jamaica Dancehall',
    description: 'Dancehall & reggae energy for the culture',
    genre: 'Dancehall / Reggae',
    url:
        'https://stream.jamaicadancehallradio.com/listen/jamaica_dancehall_radio/radio.mp3',
    artwork: AppConfig.logoAsset,
  ),
  RadioStation(
    id: 5,
    name: 'Reggae Spin',
    description: 'Reggae, dancehall & afrobeat around the clock',
    genre: 'Reggae / Afrobeat',
    url: 'https://reggaespin.media:8010/radio',
    artwork: AppConfig.logoAsset,
  ),
  RadioStation(
    id: 6,
    name: 'Mouv Dancehall',
    description: 'French urban & dancehall from Radio France',
    genre: 'Urban / Dancehall',
    url: 'https://icecast.radiofrance.fr/mouvdancehall-hifi.aac',
    artwork: AppConfig.logoAsset,
  ),
];
