import 'package:flutter/widgets.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

/// Retourne un [FaIcon] à partir du champ `icone` de l'API Django,
/// au format "style,icon-name" (ex: "fas,briefcase-medical").
/// Retourne une icône par défaut si le nom est inconnu.
/// Map publique nom FA → IconData, utilisable pour la recherche d'icônes.
/// Clé = nom kebab-case FA5/FA6, valeur = IconData font_awesome_flutter.
const Map<String, IconData> faIconMap = _map;

Widget buildFaIcon(String? icone, {Color? color, double size = 20}) {
  if (icone == null || icone.isEmpty) {
    return FaIcon(FontAwesomeIcons.circleDot, color: color, size: size);
  }

  final parts = icone.split(',');
  final iconName = parts.length == 2 ? parts[1] : parts[0];
  final iconData = _map[iconName] ?? FontAwesomeIcons.circleDot;
  return FaIcon(iconData, color: color, size: size);
}

// Mapping FA5/FA6 kebab-case → FontAwesomeIcons constant (FA6/font_awesome_flutter v10)
const _map = <String, IconData>{
  // Santé & médical
  'briefcase-medical': FontAwesomeIcons.briefcaseMedical,
  'heart': FontAwesomeIcons.heart,
  'heart-pulse': FontAwesomeIcons.heartPulse,
  'heartbeat': FontAwesomeIcons.heartPulse,
  'pills': FontAwesomeIcons.pills,
  'syringe': FontAwesomeIcons.syringe,
  'stethoscope': FontAwesomeIcons.stethoscope,
  'hospital': FontAwesomeIcons.hospital,
  'thermometer': FontAwesomeIcons.temperatureHalf,
  'weight': FontAwesomeIcons.weightScale,
  'weight-scale': FontAwesomeIcons.weightScale,
  'lungs': FontAwesomeIcons.lungs,
  'brain': FontAwesomeIcons.brain,
  'tooth': FontAwesomeIcons.tooth,
  'bone': FontAwesomeIcons.bone,
  'eye': FontAwesomeIcons.eye,
  'ear-deaf': FontAwesomeIcons.earDeaf,
  'wheelchair': FontAwesomeIcons.wheelchair,
  'band-aid': FontAwesomeIcons.bandage,
  'bandage': FontAwesomeIcons.bandage,
  'dumbbell': FontAwesomeIcons.dumbbell,
  'user-md': FontAwesomeIcons.userDoctor,
  'user-doctor': FontAwesomeIcons.userDoctor,

  // Visages & émotions
  'smile': FontAwesomeIcons.faceSmile,
  'frown': FontAwesomeIcons.faceFrown,
  'frown-open': FontAwesomeIcons.faceFrownOpen,
  'face-frown-open': FontAwesomeIcons.faceFrownOpen,
  'meh': FontAwesomeIcons.faceMeh,
  'grin': FontAwesomeIcons.faceGrin,
  'laugh': FontAwesomeIcons.faceLaugh,
  'sad-tear': FontAwesomeIcons.faceSadTear,
  'tired': FontAwesomeIcons.faceTired,
  'angry': FontAwesomeIcons.faceAngry,
  'kiss': FontAwesomeIcons.faceKiss,
  'surprise': FontAwesomeIcons.faceSurprise,
  'dizzy': FontAwesomeIcons.faceDizzy,
  'grimace': FontAwesomeIcons.faceGrimace,

  // Sport & activité
  'running': FontAwesomeIcons.personRunning,
  'person-running': FontAwesomeIcons.personRunning,
  'walking': FontAwesomeIcons.personWalking,
  'person-walking': FontAwesomeIcons.personWalking,
  'biking': FontAwesomeIcons.personBiking,
  'bicycle': FontAwesomeIcons.bicycle,
  'swimming-pool': FontAwesomeIcons.waterLadder,
  'person-swimming': FontAwesomeIcons.personSwimming,
  'swimmer': FontAwesomeIcons.personSwimming,
  'hiking': FontAwesomeIcons.personHiking,
  'skiing': FontAwesomeIcons.personSkiing,
  'football': FontAwesomeIcons.football,
  'basketball': FontAwesomeIcons.basketball,
  'volleyball-ball': FontAwesomeIcons.volleyball,
  'table-tennis': FontAwesomeIcons.tableTennisPaddleBall,
  'golf-ball': FontAwesomeIcons.golfBallTee,
  'trophy': FontAwesomeIcons.trophy,
  'medal': FontAwesomeIcons.medal,
  'stopwatch': FontAwesomeIcons.stopwatch,

  // Alimentation
  'utensils': FontAwesomeIcons.utensils,
  'coffee': FontAwesomeIcons.mugHot,
  'mug-hot': FontAwesomeIcons.mugHot,
  'wine-glass': FontAwesomeIcons.wineGlass,
  'wine-bottle': FontAwesomeIcons.wineBottle,
  'beer': FontAwesomeIcons.beerMugEmpty,
  'beer-mug-empty': FontAwesomeIcons.beerMugEmpty,
  'apple-alt': FontAwesomeIcons.appleWhole,
  'apple-whole': FontAwesomeIcons.appleWhole,
  'carrot': FontAwesomeIcons.carrot,
  'lemon': FontAwesomeIcons.lemon,
  'pizza-slice': FontAwesomeIcons.pizzaSlice,
  'hamburger': FontAwesomeIcons.burger,
  'burger': FontAwesomeIcons.burger,
  'ice-cream': FontAwesomeIcons.iceCream,
  'drumstick-bite': FontAwesomeIcons.drumstickBite,
  'fish': FontAwesomeIcons.fish,
  'egg': FontAwesomeIcons.egg,
  'bread-slice': FontAwesomeIcons.breadSlice,
  'glass-water': FontAwesomeIcons.glassWater,
  'bottle-water': FontAwesomeIcons.bottleWater,

  // Sommeil & repos
  'bed': FontAwesomeIcons.bed,
  'moon': FontAwesomeIcons.moon,
  'sun': FontAwesomeIcons.sun,
  'cloud-moon': FontAwesomeIcons.cloudMoon,
  'snooze': FontAwesomeIcons.bellSlash,

  // Travail & productivité
  'briefcase': FontAwesomeIcons.briefcase,
  'laptop': FontAwesomeIcons.laptop,
  'keyboard': FontAwesomeIcons.keyboard,
  'book': FontAwesomeIcons.book,
  'book-open': FontAwesomeIcons.bookOpen,
  'pencil-alt': FontAwesomeIcons.pencil,
  'pencil': FontAwesomeIcons.pencil,
  'check': FontAwesomeIcons.check,
  'check-circle': FontAwesomeIcons.circleCheck,
  'tasks': FontAwesomeIcons.listCheck,
  'list-check': FontAwesomeIcons.listCheck,
  'calendar': FontAwesomeIcons.calendar,
  'calendar-check': FontAwesomeIcons.calendarCheck,
  'clock': FontAwesomeIcons.clock,
  'hourglass': FontAwesomeIcons.hourglass,
  'hourglass-half': FontAwesomeIcons.hourglassHalf,

  // Transports
  'car': FontAwesomeIcons.car,
  'bus': FontAwesomeIcons.bus,
  'train': FontAwesomeIcons.train,
  'plane': FontAwesomeIcons.plane,
  'motorcycle': FontAwesomeIcons.motorcycle,
  'subway': FontAwesomeIcons.trainSubway,

  // Nature & météo
  'tree': FontAwesomeIcons.tree,
  'leaf': FontAwesomeIcons.leaf,
  'seedling': FontAwesomeIcons.seedling,
  'cloud': FontAwesomeIcons.cloud,
  'cloud-rain': FontAwesomeIcons.cloudRain,
  'snowflake': FontAwesomeIcons.snowflake,
  'fire': FontAwesomeIcons.fire,
  'bolt': FontAwesomeIcons.bolt,
  'wind': FontAwesomeIcons.wind,
  'umbrella': FontAwesomeIcons.umbrella,

  // Divers
  'star': FontAwesomeIcons.star,
  'flag': FontAwesomeIcons.flag,
  'home': FontAwesomeIcons.house,
  'house': FontAwesomeIcons.house,
  'music': FontAwesomeIcons.music,
  'gamepad': FontAwesomeIcons.gamepad,
  'tv': FontAwesomeIcons.tv,
  'mobile-alt': FontAwesomeIcons.mobileScreen,
  'money-bill': FontAwesomeIcons.moneyBill,
  'piggy-bank': FontAwesomeIcons.piggyBank,
  'gift': FontAwesomeIcons.gift,
  'camera': FontAwesomeIcons.camera,
  'paint-brush': FontAwesomeIcons.paintbrush,
  'paintbrush': FontAwesomeIcons.paintbrush,
  'graduation-cap': FontAwesomeIcons.graduationCap,
  'dog': FontAwesomeIcons.dog,
  'cat': FontAwesomeIcons.cat,
  'spa': FontAwesomeIcons.spa,
  'smile-beam': FontAwesomeIcons.faceSmileBeam,

  // FA5 → FA6 renommages fréquents
  'bomb': FontAwesomeIcons.bomb,
  'external-link-alt': FontAwesomeIcons.arrowUpRightFromSquare,
  'barcode': FontAwesomeIcons.barcode,
  'cut': FontAwesomeIcons.scissors,
  'scissors': FontAwesomeIcons.scissors,
  'hand-scissors': FontAwesomeIcons.handScissors,
  'road': FontAwesomeIcons.road,
  'flushed': FontAwesomeIcons.faceFlushed,
  'face-flushed': FontAwesomeIcons.faceFlushed,
  'headphones-alt': FontAwesomeIcons.headphones,
  'headphones': FontAwesomeIcons.headphones,
};
