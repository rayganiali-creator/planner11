// «منبعِ واحدِ حقیقت» برای Free/Pro: هر قابلیتِ محدود/قفل در یک جا تعریف می‌شود (چه چیز رایگان است، چه چیز پرو، پیامِ محدودیت).
// هیچ صفحه‌ای متنِ Pro را خودش hard-code نمی‌کند؛ از این جدول و ویجت‌های ui/pro_widgets.dart می‌خواند.
// وضعیتِ پرو فقط از state['isPremium'] می‌آید که همیشه از recomputeTrustedPremiumFlag (رسیدِ بازار/کدِ مدیر) ساخته می‌شود.
enum ProFeature { habits, books, voiceNotes, itemReminders, todoRepeatDays, subtasks, pomodoroCustom, challengesCustom, avatarItems, triggerHistory, smartAnalysis }

class ProInfo {
  final String titleFa, titleEn;
  final String freeFa, freeEn; // رایگان چیست/چه محدودیتی دارد
  final String proFa, proEn; // پرو چه می‌دهد
  final String lockFa, lockEn; // پیامِ کوتاهِ قفل/محدودیت (فقط برای کاربر رایگان)
  const ProInfo(this.titleFa, this.titleEn, this.freeFa, this.freeEn, this.proFa, this.proEn, this.lockFa, this.lockEn);
}

const Map<ProFeature, ProInfo> proInfos = {
  ProFeature.habits: ProInfo('تعداد عادت‌ها', 'Number of habits', 'حداکثر ۳ عادت فعال', 'Up to 3 active habits', 'عادت‌های نامحدود', 'Unlimited habits', 'در نسخه‌ی رایگان حداکثر ۳ عادت فعال می‌توانید داشته باشید. برای عادت‌های نامحدود، پرو را تهیه کنید.', 'The free plan allows up to 3 active habits. Get Pro for unlimited habits.'),
  ProFeature.books: ProInfo('کتابخانه', 'Library', 'حداکثر ۳ کتابِ در حال مطالعه', 'Up to 3 books in progress', 'کتاب‌های نامحدود', 'Unlimited books', 'در نسخه‌ی رایگان حداکثر ۳ کتاب در حال مطالعه می‌توانید داشته باشید. با تمام کردن یک کتاب جا باز می‌شود، یا پرو را تهیه کنید.', 'The free plan allows 3 books in progress. Finish one to free a slot, or get Pro.'),
  ProFeature.voiceNotes: ProInfo('یادداشت صوتی کتاب', 'Book voice notes', 'ندارد', 'Not included', 'ضبط و پخش یادداشت صوتی برای هر کتاب', 'Record and play voice notes per book', 'یادداشت صوتی برای کتاب‌ها از امکانات پرو است.', 'Voice notes are a Pro feature.'),
  ProFeature.itemReminders: ProInfo('یادآور یادداشت و کتاب', 'Note & book reminders', 'ندارد (یادآور عادت و کار رایگان است)', 'Not included (habit and task reminders are free)', 'یادآور با تکرار برای یادداشت‌ها و کتاب‌ها', 'Repeating reminders for notes and books', 'یادآوری یادداشت و کتاب از امکانات پرو است.', 'Reminders for notes and books are a Pro feature.'),
  ProFeature.todoRepeatDays: ProInfo('تکرار در روزهای خاص', 'Custom-day repeat', 'بدون تکرار یا همه‌روزه', 'No repeat or daily', 'تکرار در روزهای دلخواه هفته', 'Repeat on any weekdays', 'تکرار در روزهای خاص هفته از امکانات پرو است. (در نسخه‌ی رایگان: بدون تکرار یا همه‌روزه)', 'Repeating on specific weekdays is a Pro feature. (Free: no repeat or daily)'),
  ProFeature.subtasks: ProInfo('زیرتسک‌ها', 'Subtasks', 'حداکثر ۳ زیرتسک برای هر کار', 'Up to 3 subtasks per task', 'زیرتسک نامحدود', 'Unlimited subtasks', 'در نسخه‌ی رایگان هر کار حداکثر ۳ زیرتسک دارد. زیرتسک نامحدود از امکانات پرو است.', 'Free tasks have up to 3 subtasks. Unlimited subtasks are a Pro feature.'),
  ProFeature.pomodoroCustom: ProInfo('زمان‌های پومودورو', 'Pomodoro durations', '۲۵ دقیقه تمرکز، ۵ و ۱۵ دقیقه استراحت', '25 min focus, 5 & 15 min breaks', 'زمان‌های دلخواه', 'Custom durations', 'زمان‌های دلخواه پومودورو از امکانات پرو است.', 'Custom Pomodoro times are a Pro feature.'),
  ProFeature.challengesCustom: ProInfo('چالش‌ها', 'Challenges', 'چالش‌های آماده', 'Ready-made challenges', 'ساخت چالش شخصی و دریافت مدال', 'Custom challenges and medals', 'ساخت چالش شخصی و دریافت مدال از امکانات پرو است.', 'Custom challenges and medals are a Pro feature.'),
  ProFeature.avatarItems: ProInfo('آیتم‌های آواتار', 'Avatar items', 'انتخاب مرد/زن و مدل‌ها رایگان است', 'Gender and models are free', 'خرید و پوشیدن آیتم‌ها با سکه', 'Buy and wear items with coins', 'آیتم‌های آواتار با نسخه‌ی پرو باز می‌شوند و بعد با سکه خریده می‌شوند. انتخاب مرد یا زن و مدل‌ها رایگان است.', 'Avatar items unlock with Pro and are then bought with coins. Gender and models are free.'),
  ProFeature.triggerHistory: ProInfo('محرک‌ها و علت‌ها', 'Triggers & reasons', 'تاریخچه‌ی ۷ روز اخیر', 'Last 7 days of history', 'تاریخچه‌ی کامل', 'Full history', 'در نسخه‌ی رایگان فقط ۷ روز اخیرِ محرک‌ها و علت‌ها نمایش داده می‌شود.', 'The free plan shows only the last 7 days of triggers and reasons.'),
  ProFeature.smartAnalysis: ProInfo('تحلیل هوشمند', 'Smart analysis', 'ندارد (تحلیلِ پایه رایگان است)', 'Not included (basic analytics is free)', 'امتیاز رفتار، تمرکز امروز، بینش‌ها و جزئیات', 'Behavior score, today’s focus, insights and details', 'تحلیل هوشمند از امکانات پرو است.', 'Smart analysis is a Pro feature.'),
};

/// تنها منبعِ پرو بودن (state['isPremium'] از رسیدِ معتبر/کدِ مدیر محاسبه می‌شود)
bool isProState(Map st) => st['isPremium'] == true;
