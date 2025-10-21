import 'package:flutter/material.dart';
import 'package:saegim/core/theme/theme_extensions.dart';
import 'package:saegim/shared/widgets/common_app_bar.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CommonAppBar(
        title: '개인정보 처리방침',
        showBackButton: true,
        showMenuButton: false,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        children: const [
          _PolicySection(
            title: '1. 개인정보 수집 및 이용 목적',
            points: [
              '회원 가입 및 본인 확인: 이메일, 닉네임 등 기본 정보로 계정을 생성하고 본인 여부를 확인합니다.',
              '서비스 제공 및 운영: 다이어리 작성, 감정 분석, AI 추천 기능과 같은 주요 서비스를 제공하기 위해 데이터를 활용합니다.',
              '계정 복구 및 고객 지원: 계정 분실 또는 탈퇴 복구 요청 시 본인 확인을 위해 필요한 정보를 확인합니다.',
              '알림 및 안내: 다이어리 작성 알림, 주간 리포트, 서비스 공지사항을 전달합니다.',
            ],
          ),
          _PolicySection(
            title: '2. 수집하는 개인정보 항목',
            points: [
              '필수 정보: 이메일, 닉네임, 비밀번호(또는 소셜 로그인 식별자), 서비스 이용 기록, 기기 정보.',
              '선택 정보: 프로필 이미지, 사용자 메모, 감정 태그 등 사용자가 직접 입력한 추가 정보.',
              '콘텐츠 데이터: 작성한 다이어리 본문, 이미지, 감정 분석 결과와 같이 서비스 이용을 통해 생성된 데이터.',
            ],
          ),
          _PolicySection(
            title: '3. 개인정보 보관 및 보호',
            points: [
              '데이터는 국내 리전의 보안 인증을 획득한 클라우드 환경에 암호화되어 저장됩니다.',
              '사용자 비밀번호는 해시 알고리즘을 통해 안전하게 보관하며, 복구가 불가능한 방식으로 관리합니다.',
              '서비스 내부 접근 권한을 최소화하여 운영하며, 개인정보 처리 담당자는 정기적인 보안 교육을 이수합니다.',
            ],
          ),
          _PolicySection(
            title: '4. 개인정보 이용 기간 및 파기',
            points: [
              '회원 탈퇴 시 즉시 모든 개인정보를 삭제하며, 복구 요청을 대비해 30일간 삭제 보류 후 완전 파기됩니다.',
              '관계 법령에서 별도로 보관을 요구하는 경우(전자상거래법, 통신비밀보호법 등) 해당 기간 동안 안전하게 보관 후 파기합니다.',
              '로그 기록, 접속 IP 등 보안 목적의 데이터는 3개월 동안 보관 후 삭제됩니다.',
            ],
          ),
          _PolicySection(
            title: '5. 개인정보 제3자 제공 및 위탁',
            points: [
              '원칙적으로 이용자의 동의 없이 제3자에게 개인정보를 제공하지 않습니다.',
              '서비스 운영에 필요한 일부 업무(예: 푸시 알림 발송, 클라우드 인프라 운영)는 신뢰할 수 있는 외부 업체에 위탁하며, 관련 계약을 통해 안전하게 관리합니다.',
            ],
          ),
          _PolicySection(
            title: '6. 이용자의 권리와 행사 방법',
            points: [
              '언제든지 개인정보 열람, 수정, 삭제, 처리 정지를 요청할 수 있으며 앱 내 설정 > 개인정보 메뉴 또는 고객 지원을 통해 문의하실 수 있습니다.',
              '계정 복구 요청 시 본인 확인을 위해 가입 이메일 및 기타 인증 절차를 진행하며, 30일 이내 복구가 가능합니다.',
              '탈퇴 후 30일이 경과하면 모든 데이터가 완전히 삭제되어 복구가 불가능합니다.',
            ],
          ),
          _PolicySection(
            title: '7. 안전한 서비스 이용을 위한 안내',
            points: [
              '비밀번호는 타 서비스와 다른 조합으로 설정하고 주기적으로 변경해 주세요.',
              '공용 기기에서는 로그아웃을 수행하고 자동 로그인 정보를 저장하지 않는 것을 권장합니다.',
              '의심스러운 활동이나 보안 위협이 감지되면 즉시 고객 지원으로 신고해 주세요.',
            ],
          ),
          _PolicySection(
            title: '8. 개인정보 보호책임자 및 문의',
            points: [
              '책임자: 새김 개인정보 보호 책임자',
              '이메일: privacy@saegim.app',
              '문의 방법: 앱 내 고객 지원 > 1:1 문의 또는 위 이메일로 연락해 주세요.',
            ],
          ),
          _PolicySection(
            title: '9. 개인정보 처리방침 변경 안내',
            points: [
              '법령 변경 또는 서비스 개선에 따라 정책을 수정할 수 있으며, 변경 시 최소 7일 전 앱 공지 및 이메일로 안내합니다.',
              '중요한 내용(이용 목적, 수집 항목 변경 등) 변경 시에는 사전 동의를 다시 받습니다.',
            ],
          ),
        ],
      ),
    );
  }
}

class _PolicySection extends StatelessWidget {
  const _PolicySection({
    required this.title,
    required this.points,
  });

  final String title;
  final List<String> points;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 12),
          ...points.map(
            (point) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('• ', style: TextStyle(color: context.secondaryText)),
                  Expanded(
                    child: Text(
                      point,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        height: 1.5,
                        color: context.secondaryText,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
