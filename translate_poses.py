#!/usr/bin/env python3
"""Add 7 language translations to PoseCatalog.swift LocalizedString/LocalizedStringArray calls."""

import re
import sys

FILE = '/home/user/NATURaL/BonhommeCore/Sources/BonhommeCore/Models/PoseCatalog.swift'

# Translation dictionary: maps (pose_context, field, en_text) -> translations dict
# We'll build this programmatically based on the English text

TRANSLATIONS = {
    # === seatedMeditation ===
    ("Seated Meditation",): {
        "es": "Meditación sentada", "ja": "座った瞑想", "zh": "坐姿冥想",
        "ko": "앉은 명상", "ru": "Медитация сидя", "de": "Sitzende Meditation",
        "ar": "التأمل جلوساً"
    },
    ("Sit comfortably with your feet flat on the floor, hands resting gently on your lap or thighs. Close your eyes or soften your gaze. Focus on the natural rhythm of your breath, observing each inhale and exhale without trying to change it.",): {
        "es": "Siéntese cómodamente con los pies apoyados en el suelo y las manos descansando suavemente en el regazo o los muslos. Cierre los ojos o suavice la mirada. Concéntrese en el ritmo natural de su respiración, observando cada inhalación y exhalación sin intentar cambiarla.",
        "ja": "足を床に平らにつけて快適に座り、手を膝や太ももの上に軽く置きます。目を閉じるか、視線を柔らかくします。呼吸の自然なリズムに集中し、変えようとせずに吸う息と吐く息を観察します。",
        "zh": "舒适地坐着，双脚平放在地板上，双手轻轻放在膝上或大腿上。闭上眼睛或柔化目光。关注呼吸的自然节奏，观察每次吸气和呼气，不试图改变它。",
        "ko": "발을 바닥에 평평하게 놓고 편안하게 앉아 손을 무릎이나 허벅지 위에 가볍게 올립니다. 눈을 감거나 시선을 부드럽게 합니다. 호흡의 자연스러운 리듬에 집중하며, 바꾸려 하지 말고 들숨과 날숨을 관찰합니다.",
        "ru": "Сядьте удобно, стопы ровно на полу, руки мягко лежат на коленях или бёдрах. Закройте глаза или смягчите взгляд. Сосредоточьтесь на естественном ритме дыхания, наблюдая каждый вдох и выдох, не пытаясь его изменить.",
        "de": "Setzen Sie sich bequem mit den Füßen flach auf dem Boden, Hände ruhen sanft auf dem Schoß oder den Oberschenkeln. Schließen Sie die Augen oder lassen Sie den Blick weich werden. Konzentrieren Sie sich auf den natürlichen Rhythmus Ihres Atems, beobachten Sie jedes Ein- und Ausatmen, ohne es verändern zu wollen.",
        "ar": "اجلس بشكل مريح مع وضع قدميك بشكل مسطح على الأرض ويديك مسترخيتين برفق على حضنك أو فخذيك. أغلق عينيك أو ليّن نظرتك. ركّز على الإيقاع الطبيعي لتنفسك، وراقب كل شهيق وزفير دون محاولة تغييره."
    },
    ("Close your eyes. Breathe naturally. Observe each breath. Let each exhale release a little more tension.",): {
        "es": "Cierre los ojos. Respire naturalmente. Observe cada respiración. Deje que cada exhalación libere un poco más de tensión.",
        "ja": "目を閉じてください。自然に呼吸してください。一呼吸ごとに観察してください。吐くたびに少しずつ緊張を手放しましょう。",
        "zh": "闭上眼睛。自然呼吸。观察每一次呼吸。让每次呼气释放更多紧张。",
        "ko": "눈을 감으세요. 자연스럽게 호흡하세요. 매 호흡을 관찰하세요. 매 날숨마다 긴장을 조금씩 더 풀어주세요.",
        "ru": "Закройте глаза. Дышите естественно. Наблюдайте за каждым вдохом. Пусть каждый выдох снимает немного больше напряжения.",
        "de": "Schließen Sie die Augen. Atmen Sie natürlich. Beobachten Sie jeden Atemzug. Lassen Sie mit jedem Ausatmen etwas mehr Spannung los.",
        "ar": "أغلق عينيك. تنفّس بشكل طبيعي. راقب كل نَفَس. دع كل زفير يحرّر مزيداً من التوتر."
    },
    # seatedMeditation modifications
    ("Keep eyes slightly open with a soft downward gaze if closing them feels uncomfortable",
     "Place a hand on your belly to feel the breath"): {
        "es": ["Mantenga los ojos ligeramente abiertos con una mirada suave hacia abajo si cerrarlos resulta incómodo",
               "Coloque una mano en el abdomen para sentir la respiración"],
        "ja": ["目を閉じるのが不快に感じる場合は、目を少し開けて柔らかく下を見てください",
               "呼吸を感じるためにお腹に手を置いてください"],
        "zh": ["如果闭眼感到不适，可以微微睁开眼睛，目光柔和地向下看",
               "将一只手放在腹部感受呼吸"],
        "ko": ["눈을 감는 것이 불편하면 눈을 살짝 뜨고 부드럽게 아래를 바라보세요",
               "호흡을 느끼기 위해 배에 손을 올려놓으세요"],
        "ru": ["Держите глаза слегка приоткрытыми с мягким взглядом вниз, если закрывать их неудобно",
               "Положите руку на живот, чтобы чувствовать дыхание"],
        "de": ["Halten Sie die Augen leicht geöffnet mit einem sanften Blick nach unten, wenn das Schließen unangenehm ist",
               "Legen Sie eine Hand auf den Bauch, um den Atem zu spüren"],
        "ar": ["أبقِ عينيك مفتوحتين قليلاً مع نظرة ناعمة للأسفل إذا كان إغلاقهما غير مريح",
               "ضع يداً على بطنك لتشعر بالتنفس"]
    },
    ("Natural breathing — observe without controlling",): {
        "es": "Respiración natural — observe sin controlar",
        "ja": "自然な呼吸 — コントロールせずに観察する",
        "zh": "自然呼吸——观察而不控制",
        "ko": "자연스러운 호흡 — 조절하지 말고 관찰하기",
        "ru": "Естественное дыхание — наблюдайте, не контролируя",
        "de": "Natürliche Atmung — beobachten ohne zu kontrollieren",
        "ar": "تنفس طبيعي — راقب دون التحكم"
    },
}

# Rather than a lookup table approach, let me do a line-by-line approach
# that finds en/fr-only blocks and adds translations

def main():
    with open(FILE, 'r') as f:
        content = f.read()

    lines = content.split('\n')
    result = []
    i = 0

    while i < len(lines):
        line = lines[i]
        stripped = line.strip()

        # Handle single-line empty LocalizedStringArray
        if 'LocalizedStringArray(en: [], fr: [])' in stripped and 'es:' not in stripped:
            result.append(line.replace(
                'LocalizedStringArray(en: [], fr: [])',
                'LocalizedStringArray(en: [], fr: [], es: [], ja: [], zh: [], ko: [], ru: [], de: [], ar: [])'
            ))
            i += 1
            continue

        # Handle multi-line LocalizedString or LocalizedStringArray blocks
        if ('LocalizedString(' in stripped or 'LocalizedStringArray(' in stripped) and stripped.endswith('('):
            # Collect the full block
            block_lines = [line]
            paren_depth = 1
            j = i + 1
            while j < len(lines) and paren_depth > 0:
                block_lines.append(lines[j])
                paren_depth += lines[j].count('(') - lines[j].count(')')
                j += 1

            block_text = '\n'.join(block_lines)

            # Check if already has es: translations
            if 'es:' not in block_text and 'fr:' in block_text:
                # This block needs translations - output it and mark for manual review
                # For now, just pass through (we'll handle with targeted edits)
                pass

            result.extend(block_lines)
            i = j
            continue

        result.append(line)
        i += 1

    with open(FILE, 'w') as f:
        f.write('\n'.join(result))

if __name__ == '__main__':
    main()
