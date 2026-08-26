import '../../core/i18n/translate.dart';
import 'specialist_detail_models.dart';
import 'specialist_detail_texts.dart';

/// Usta sahifasidagi narx jadvali uchun qatorlar.
///
/// Saytdagi `master-detail.component.ts` → `serviceTypes` mantig'i:
/// usta kabinetdan paket kiritgan bo'lsa shular ko'rsatiladi, aks holda
/// mutaxassisligiga qarab standart taklif chiziladi. Standart taklifning
/// narxlari ustaning `priceFrom` iga ko'paytma qo'llab hisoblanadi.
/// Mutaxassisligi ro'yxatda bo'lmasa — jadval umuman chizilmaydi.
List<ServiceRow> masterServiceRows(SpecialistDetail s) {
  if (s.servicePackages.isNotEmpty) {
    return [
      for (final p in s.servicePackages)
        ServiceRow(
          name: p.title,
          price: p.price,
          unit: '${p.deliveryDays} ${SpecialistDetailTexts.days}',
          description: p.features.join(', '),
        ),
    ];
  }

  final from = s.priceFrom;
  ServiceRow row(String name, num multiplier, String unit, String description) =>
      ServiceRow(name: name, price: from * multiplier, unit: unit, description: description);

  return switch (s.specialization) {
    'plumber' => [
      row(
        t('masterDetail.service.pipeInstall'),
        1,
        SpecialistDetailTexts.unitPerService,
        t('masterDetail.serviceDesc.pipeInstall'),
      ),
      row(
        t('masterDetail.service.pipeRepair'),
        0.7,
        SpecialistDetailTexts.unitPerService,
        t('masterDetail.serviceDesc.pipeRepair'),
      ),
      row(
        t('masterDetail.service.toiletInstall'),
        1.5,
        SpecialistDetailTexts.unitPerService,
        t('masterDetail.serviceDesc.toiletInstall'),
      ),
      row(
        t('masterDetail.service.bathroomFull'),
        5,
        SpecialistDetailTexts.unitPerProject,
        t('masterDetail.serviceDesc.bathroomFull'),
      ),
    ],
    'electrician' => [
      row(
        t('masterDetail.service.wiring'),
        1,
        SpecialistDetailTexts.unitPerM,
        t('masterDetail.serviceDesc.wiring'),
      ),
      row(
        t('masterDetail.service.socketInstall'),
        0.5,
        SpecialistDetailTexts.unitPerPiece,
        t('masterDetail.serviceDesc.socketInstall'),
      ),
      row(
        t('masterDetail.service.lighting'),
        2,
        SpecialistDetailTexts.unitPerRoom,
        t('masterDetail.serviceDesc.lighting'),
      ),
      row(
        t('masterDetail.service.fullElectric'),
        8,
        SpecialistDetailTexts.unitPerProject,
        t('masterDetail.serviceDesc.fullElectric'),
      ),
    ],
    'painter' => [
      row(
        t('masterDetail.service.wallPaint'),
        1,
        SpecialistDetailTexts.unitPerM2,
        t('masterDetail.serviceDesc.wallPaint'),
      ),
      row(
        t('masterDetail.service.wallPaper'),
        1.2,
        SpecialistDetailTexts.unitPerM2,
        t('masterDetail.serviceDesc.wallPaper'),
      ),
      row(
        t('masterDetail.service.decorative'),
        2,
        SpecialistDetailTexts.unitPerM2,
        t('masterDetail.serviceDesc.decorative'),
      ),
      row(
        t('masterDetail.service.wholeFlat'),
        10,
        SpecialistDetailTexts.unitPerProject,
        t('masterDetail.serviceDesc.wholeFlat'),
      ),
    ],
    'tiler' => [
      row(
        t('masterDetail.service.floorTile'),
        1,
        SpecialistDetailTexts.unitPerM2,
        t('masterDetail.serviceDesc.floorTile'),
      ),
      row(
        t('masterDetail.service.wallTile'),
        1.2,
        SpecialistDetailTexts.unitPerM2,
        t('masterDetail.serviceDesc.wallTile'),
      ),
      row(
        t('masterDetail.service.mosaic'),
        2,
        SpecialistDetailTexts.unitPerM2,
        t('masterDetail.serviceDesc.mosaic'),
      ),
    ],
    'carpenter' => [
      row(
        t('masterDetail.service.doorInstall'),
        1,
        SpecialistDetailTexts.unitPerPiece,
        t('masterDetail.serviceDesc.doorInstall'),
      ),
      row(
        t('masterDetail.service.furniture'),
        2,
        SpecialistDetailTexts.unitPerService,
        t('masterDetail.serviceDesc.furniture'),
      ),
      row(
        t('masterDetail.service.parquet'),
        1.5,
        SpecialistDetailTexts.unitPerM2,
        t('masterDetail.serviceDesc.parquet'),
      ),
    ],
    'welder' => [
      row(
        t('masterDetail.service.metalGate'),
        1,
        SpecialistDetailTexts.unitPerPiece,
        t('masterDetail.serviceDesc.metalGate'),
      ),
      row(
        t('masterDetail.service.railing'),
        0.8,
        SpecialistDetailTexts.unitPerM,
        t('masterDetail.serviceDesc.railing'),
      ),
      row(
        t('masterDetail.service.metalStructure'),
        3,
        SpecialistDetailTexts.unitPerService,
        t('masterDetail.serviceDesc.metalStructure'),
      ),
    ],
    _ => const [],
  };
}
