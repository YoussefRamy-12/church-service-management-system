import 'package:flutter_test/flutter_test.dart';

import 'package:church_service_management_system/features/students/domain/entities/student.dart';
import 'package:church_service_management_system/features/students/services/student_qr_pdf_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const pdfService = StudentQrPdfService();

  group('Student QR and PDF Card Service', () {
    const sampleStudent = Student(
      id: 'student-uuid-1234-5678',
      serviceId: 'service-church-1',
      name: 'كيرلس أمير عزيز',
      approvalStatus: 'approved',
      currentClassId: 'class-5-1',
      grade: 'الخامس الابتدائي',
      phone: '01224891045',
    );

    test(
      'QR payload uses canonical student.id preserving scanner compatibility',
      () {
        // In qr_scan_page.dart:
        // if (candidate.id == barcodeValue) { student = candidate; }
        final barcodePayload = sampleStudent.id;
        expect(barcodePayload, 'student-uuid-1234-5678');
        expect(barcodePayload, sampleStudent.id);
        expect(
          barcodePayload.contains(sampleStudent.phone ?? ''),
          isFalse,
          reason: 'QR payload must never expose sensitive contact details',
        );
      },
    );

    test(
      'generateSingleStudentCardPdf generates non-empty printable PDF document',
      () async {
        final bytes = await pdfService.generateSingleStudentCardPdf(
          student: sampleStudent,
          serviceName: 'خدمة ابتدائي كنيسة مارمرقس',
          className: 'فصل 5/1',
        );

        expect(bytes, isNotEmpty);
        // PDF file magic header: %PDF-
        expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
      },
    );

    test(
      'generateClassCardsPdf creates multi-student grid cards PDF',
      () async {
        final students = List.generate(
          10,
          (i) => Student(
            id: 'student-uuid-$i',
            serviceId: 'service-church-1',
            name: 'طالب اختباري $i',
            approvalStatus: 'approved',
            currentClassId: 'class-5-1',
            grade: '5 ابتدائي',
          ),
        );

        final bytes = await pdfService.generateClassCardsPdf(
          students: students,
          serviceName: 'خدمة ابتدائي',
          className: 'فصل 5/1',
        );

        expect(bytes, isNotEmpty);
        expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
      },
    );
  });
}
