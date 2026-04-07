import re

path = 'd:\\Develop\\Personal\\vrm\\lib\\features\\influencer_profile\\influencer_profile_page.dart'
with open(path, 'r', encoding='utf-8') as f:
    text = f.read()

text = text.replace('backgroundColor: AppTheme.backgroundLight,', 'backgroundColor: context.colorScheme.surface,')
text = text.replace('color: Colors.white', 'color: context.appColors.cardBackground')
text = text.replace('color: AppTheme.forest', 'color: context.appColors.textPrimary')
text = text.replace('color: AppTheme.forestVibrant', 'color: context.colorScheme.primary')
text = text.replace('color: AppTheme.earth', 'color: context.appColors.textSecondary')
text = text.replace('color: AppTheme.textMuted', 'color: context.appColors.textSecondary')
text = text.replace('color: AppTheme.forestDark', 'color: context.colorScheme.primary')
text = text.replace('color: const Color(0xFFF1F5F9)', 'color: context.appColors.cardBorder')
text = text.replace('color: const Color(0xFFE2E8F0)', 'color: context.appColors.cardBorder')

text = text.replace('AppTheme.backgroundLight', 'context.colorScheme.surface')
text = text.replace('AppTheme.forestVibrant', 'context.colorScheme.primary')
text = text.replace('AppTheme.forest', 'context.colorScheme.primary')
text = text.replace('AppTheme.earth', 'context.appColors.textSecondary')
text = text.replace('AppTheme.textMuted', 'context.appColors.textSecondary')
text = text.replace('AppTheme.forestDark', 'context.colorScheme.primary')

text = text.replace('const Color(0xFFF1F5F9)', 'context.appColors.cardBorder')
text = text.replace('const Color(0xFFE2E8F0)', 'context.appColors.cardBorder')
text = text.replace('const Color(0xFFF1FAF5)', 'context.colorScheme.primary.withValues(alpha: 0.1)')
text = text.replace('const Color(0xFF64748B)', 'context.appColors.textSecondary')
text = text.replace('Colors.grey.withValues(alpha: 0.1)', 'context.appColors.cardBorder')


# Remove const from certain widgets since their properties now use BuildContext
text = re.sub(r'const\s+(Text\()', r'\1', text)
text = re.sub(r'const\s+(Icon\()', r'\1', text)
text = re.sub(r'const\s+(TextStyle\()', r'\1', text)
text = re.sub(r'const\s+(Expanded\(\s*child:\s*Text)', r'Expanded(\n              child: Text', text)

with open(path, 'w', encoding='utf-8') as f:
    f.write(text)

print("Replacement complete.")
