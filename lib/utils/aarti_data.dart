import 'package:flutter/material.dart';

/// A single aarti (devotional hymn) with its traditional lyrics.
class Aarti {
  final String id;
  final String title; // English title, e.g. "Ganesh Aarti"
  final String titleHindi; // Devanagari title, e.g. "श्री गणेश आरती"
  final String deity; // short deity name shown on cards
  final String icon; // emoji icon
  final Color color; // accent color for the card/detail
  final String description; // one-line intro
  final List<String> verses; // each element is one verse (group of lines)

  const Aarti({
    required this.id,
    required this.title,
    required this.titleHindi,
    required this.deity,
    required this.icon,
    required this.color,
    required this.description,
    required this.verses,
  });
}

/// All aartis available in the app (static, offline-friendly).
class AartiData {
  AartiData._();

  static const List<Aarti> aartis = [
    Aarti(
      id: 'ganesh',
      title: 'Ganesh Aarti',
      titleHindi: 'श्री गणेश आरती',
      deity: 'Lord Ganesha',
      icon: '🐘',
      color: Color(0xFFDC2626),
      description: 'Jai Ganesh Jai Ganesh Deva — the beloved Aarti of Lord Ganesha, remover of obstacles.',
      verses: [
        'जय गणेश, जय गणेश, जय गणेश देवा।\nमाता जाकी पार्वती, पिता महादेवा॥',
        'एकदन्त दयावन्त, चार भुजाधारी।\nमाथे पर तिलक सोहे, मूसे की सवारी॥\nपान चढ़े फूल चढ़े, और चढ़े मेवा।\nलड्डुअन का भोग लगे, सन्त करें सेवा॥',
        'जय गणेश, जय गणेश, जय गणेश देवा।\nमाता जाकी पार्वती, पिता महादेवा॥',
        "अँधे को आँख देत, कोढ़िन को काया।\nबाँझन को पुत्र देत, निर्धन को माया॥\n'सूर' श्याम शरण आए, सफल कीजे सेवा।\nमाता जाकी पार्वती, पिता महादेवा॥",
        'दीनन की लाज राखो, शम्भु सुतवारी।\nकामना को पूर्ण करो, जग बलिहारी॥',
        'जय गणेश, जय गणेश, जय गणेश देवा।\nमाता जाकी पार्वती, पिता महादेवा॥',
      ],
    ),
    Aarti(
      id: 'durga',
      title: 'Durga Aarti',
      titleHindi: 'जय अम्बे गौरी',
      deity: 'Maa Durga',
      icon: '🦁',
      color: Color(0xFFB91C1C),
      description: 'Jai Ambe Gauri — the powerful Aarti of Goddess Durga, slayer of Mahishasura.',
      verses: [
        'जय अम्बे गौरी, मैया जय श्यामा गौरी।\nतुमको निशिदिन ध्यावत, हरि ब्रह्मा शिवरी॥',
        'मांग सिंदूर विराजत, टीको मृगमद को।\nउज्ज्वल से दोउ नैना, चंद्रवदन नीको॥\nकनक समान कलेवर, रक्ताम्बर राजै।\nरक्तपुष्प गल माला, कंठन पर साजै॥',
        'केहरि वाहन राजत, खड्ग खप्पर धारी।\nसुर-नर मुनि जन सेवत, तिनके दुःख हारी॥\nकानन कुंडल शोभित, नासाग्रे मोती।\nकोटिक चंद्र दिवाकर, सम राजत ज्योती॥',
        'शुंभ निशुंभ बिदारे, महिषासुर घाती।\nधूम्र विलोचन नैना, निशिदिन मद माती॥\nचंड-मुंड संहारे, शोणित बीज हरे।\nमधु-कैटभ दौउ मारे, सुर भय हिं करे॥',
        'ब्रह्माणी रुद्राणी, तुम कामाक्षा वरी।\nप्रणमत जो तुमको भक्ति, कठिन कारज तारी॥\nधूप दीप फल मेवा, मां स्वीकारो।\nअंगिका करि सुर नर को, जगमग दारो॥',
        'जय अम्बे गौरी, मैया जय श्यामा गौरी।\nतुमको निशिदिन ध्यावत, हरि ब्रह्मा शिवरी॥',
      ],
    ),
    Aarti(
      id: 'lakshmi',
      title: 'Lakshmi Aarti',
      titleHindi: 'ॐ जय लक्ष्मी माता',
      deity: 'Maa Lakshmi',
      icon: '💰',
      color: Color(0xFFEAB308),
      description: 'Om Jai Lakshmi Mata — the Aarti of Goddess Lakshmi, bestower of wealth and prosperity.',
      verses: [
        'ॐ जय लक्ष्मी माता, मैया जय लक्ष्मी माता।\nतुमको निशिदिन सेवत, हरि विष्णु विधाता॥',
        'उमा, रमा, कमला, बैकुंठ निवासिनी।\nसुख-सम्पत्ति दाता, संतोष प्रकाशिनी॥\nजो कोई तुमको ध्यावत, नर-नारी।\nभव-सागर तर जाते, जनम नहिं वारी॥',
        'गज मोरा सिंह वाहन, कमल कर धारी।\nसेवत मन मोहन, सदा नर नारी॥\nनिशि दिन ध्यावत, हरि विष्णु विधाता।\nॐ जय लक्ष्मी माता, मैया जय लक्ष्मी माता॥',
      ],
    ),
    Aarti(
      id: 'shiv',
      title: 'Shiv Aarti',
      titleHindi: 'ॐ जय शिव ओंकारा',
      deity: 'Lord Shiva',
      icon: '🔱',
      color: Color(0xFF4F46E5),
      description: 'Om Jai Shiv Omkara — the sublime Aarti of Lord Shiva, the great ascetic and destroyer.',
      verses: [
        'ॐ जय शिव ओंकारा, प्रभु जय शिव ओंकारा।\nब्रह्मा विष्णु सदाशिव, अर्द्धांगी धारा॥',
        'एकानन चतुरानन, पंचानन राजे।\nहंसानन गरुड़ासन, वृषवाहन साजे॥\nदो भुज चार चतुरानन, दश भुजा सोहे।\nतीनों रूप निरखता, त्रिभुवन मन मोहे॥',
        'अक्षमाला वनमाला, रुण्डमाल धारी।\nचंदन मृगमद सोहे, भाले शशिधारी॥\nश्वेताम्बर पीताम्बर, बाघम्बर अंगे।\nसनकादिक गणनाथ, मुनीजन संगे॥',
        'काम क्रोध लोभ मोह, छूटे कर सारे।\nप्रभु चरण चित्त लागे, दास मन तारे॥\nॐ जय शिव ओंकारा, प्रभु जय शिव ओंकारा।\nब्रह्मा विष्णु सदाशिव, अर्द्धांगी धारा॥',
      ],
    ),
    Aarti(
      id: 'hanuman',
      title: 'Hanuman Aarti',
      titleHindi: 'आरती कीजै हनुमान लला की',
      deity: 'Hanuman Ji',
      icon: '🐒',
      color: Color(0xFFEA580C),
      description: 'Aarti Keejai Hanuman Lala Ki — the fiery Aarti of Lord Hanuman, the mightiest devotee.',
      verses: [
        'आरती कीजै हनुमान लला की।\nदुष्ट दलन रघुनाथ कला की॥',
        'जाके बल से गिरिवर कांपे।\nराक्षस दलन चलें जम कांपे॥\nबाल समय रवि भक्षी लियो तब।\nतीनहुं लोक भयो अंधियारो॥',
        'ताहि समय रवि भक्षी लियो तब।\nचतुर देव लियो हरि द्वारो॥\nबाल नखर्य सुंदर कर तारू।\nबारह योजन उड़ गिरि धारो॥',
        'राम काज करिबे को आतुर।\nअति विशाल देखि राहु सुर॥\nलंका स्वर्ण मयी लंका जलाई।\nभरी दुःख रावन की छाती॥',
        'देखि जन्म हनुमान लला की।\nआरती कीजै हनुमान लला की॥',
      ],
    ),
    Aarti(
      id: 'krishna',
      title: 'Krishna Aarti',
      titleHindi: 'आरती कुंजबिहारी की',
      deity: 'Lord Krishna',
      icon: '🦚',
      color: Color(0xFF2563EB),
      description: 'Aarti Kunj Bihari Ki — the enchanting Aarti of Lord Krishna, the flute-playing cowherd.',
      verses: [
        'आरती कुंजबिहारी की, श्री गिरिधर कृष्ण मुरारी की।\nगले में बैजंती माला, सजे मोर मुकुट बनमाला।\nचन्दन चर्चित कपोल, भाल मृग मद सोहे।\nविराजित कर आलि, श्री आरती कुंजबिहारी की॥',
        'मोर मुकुट पै चन्द्रिका, कमल नयन विशाला।\nजाकी छवि निरखत, नन्दनन्दन गोपाला॥\nभुज पर चन्दन द्विज माला, मुख चन्द्र सुहावे।\nछवि निरखत मन मोहे, श्री आरती कुंजबिहारी की॥',
        'जय जय श्री कृष्ण मुरारी की।\nआरती कुंजबिहारी की, श्री गिरिधर कृष्ण मुरारी की॥',
      ],
    ),
    Aarti(
      id: 'vishnu',
      title: 'Vishnu Aarti',
      titleHindi: 'ॐ जय जगदीश हरे',
      deity: 'Lord Vishnu',
      icon: '🌀',
      color: Color(0xFF1D4ED8),
      description: 'Om Jai Jagdish Hare — the universal Aarti of Lord Vishnu, the preserver of the universe.',
      verses: [
        'ॐ जय जगदीश हरे, स्वामी जय जगदीश हरे।\nभक्त जनों के संकट, दास जनों के संकट,\nक्षण में दूर करे॥',
        'जो ध्यावे फल पावे, दुख बिनसे मन का।\nस्वामी दुख बिनसे मन का।\nसुख सम्पत्ति घर आवे, सुख सम्पत्ति घर आवे,\nकष्ट मिटे तन का॥',
        'मात-पिता तुम मेरे, शरण गहूं मैं किसकी।\nस्वामी शरण गहूं मैं किसकी।\nतुम बिन और न दूजा, तुम बिन और न दूजा,\nआस करूं जिसकी॥',
        'तुम पूरण परमात्मा, तुम अंतर्यामी।\nस्वामी तुम अंतर्यामी।\nपार ब्रह्म परमेश्वर, पार ब्रह्म परमेश्वर,\nतुम सबके स्वामी॥',
        'तुम करुणा के सागर, तुम पालनकर्ता।\nस्वामी तुम पालनकर्ता।\nमैं मूरख खल कामी, मैं सेवक तुम स्वामी,\nकृपा करो भर्ता॥',
        'दीनबंधु दुखहर्ता, ठाकुर तुम मेरे।\nस्वामी ठाकुर तुम मेरे।\nअपने हाथ उठाओ, अपने हाथ उठाओ,\nद्वार पड़ा तेरे॥',
        'विषय विकार मिटाओ, पाप हरो देवा।\nस्वामी पाप हरो देवा।\nश्रद्धा भक्ति बढ़ाओ, श्रद्धा भक्ति बढ़ाओ,\nसंतन की सेवा॥',
        'ॐ जय जगदीश हरे, स्वामी जय जगदीश हरे।\nभक्त जनों के संकट, दास जनों के संकट,\nक्षण में दूर करे॥',
      ],
    ),
    Aarti(
      id: 'saraswati',
      title: 'Saraswati Aarti',
      titleHindi: 'ॐ जय सरस्वती माता',
      deity: 'Maa Saraswati',
      icon: '🎼',
      color: Color(0xFFA78BFA),
      description: 'Om Jai Saraswati Mata — the Aarti of Goddess Saraswati, giver of knowledge and wisdom.',
      verses: [
        'ॐ जय सरस्वती माता, मैया जय सरस्वती माता।\nसद्गुण वैभव शालिनी, त्रिभुवन विख्याता॥',
        'चन्द्रवदनी पद्मासिनी, द्युति मंगलकारी।\nसोहे शुभ हंसावली, माता शुभकारी॥\nवीणा रख कर पुस्तक, सुन्दर हस्त धारी।\nविद्यादायिनी देवी, ज्ञान प्रकाशकारी॥',
        'ब्रह्मचारिणी सावित्री, तुम महा बलधारी।\nभक्तों के उद्धारक, संकट हरने वाली॥\nसकल दुःख हरने वाली, माता सुखकारी।\nॐ जय सरस्वती माता, मैया जय सरस्वती माता॥',
      ],
    ),
    Aarti(
      id: 'sai_baba',
      title: 'Sai Baba Aarti',
      titleHindi: 'ॐ जय साईं बाबा',
      deity: 'Sai Baba',
      icon: '🙏',
      color: Color(0xFFF97316),
      description: 'Om Jai Sai Baba — the beloved Aarti of Shirdi Sai Baba, the saint who lived for all.',
      verses: [
        'ॐ जय साईं बाबा, प्रभु जय साईं बाबा।\nतुमसे बड़ा दयालु, कोई नहीं मेरे बाबा॥',
        'भक्तन के दुःख हरता, भव भय नाशन।\nतन मन धन सब अर्पण, करते हरि दासन॥\nसाईं नाम जपते ही, संकट सब भागे।\nदर्शन की प्यासी, आत्मा तरसे॥',
        'श्रद्धा-सबुरी का बल, साईं के पासा।\nजो भी शरण पड़े, उसका कष्ट नाशा॥\nॐ जय साईं बाबा, प्रभु जय साईं बाबा।\nतुमसे बड़ा दयालु, कोई नहीं मेरे बाबा॥',
      ],
    ),
    Aarti(
      id: 'santoshi_mata',
      title: 'Santoshi Mata Aarti',
      titleHindi: 'जय सन्तोषी माता',
      deity: 'Maa Santoshi',
      icon: '🌺',
      color: Color(0xFFEC4899),
      description: 'Jai Santoshi Mata — the Aarti of Goddess Santoshi, the mother of contentment.',
      verses: [
        'जय सन्तोषी माता, मैया जय सन्तोषी माता।\nअपने सेवक जन की, सुख सम्पत्ति दाता॥',
        'सुन्दर चीर बनाकर, प्रेम सहित पहराओ।\nसन्तोषी माता जी, हम तेरी शरण पड़े॥\nसोलह श्रृंगार सजावो, माता आरती गावो।\nतुम्हारा नाम जपने से, सब कष्ट मिटा दे॥',
        'अष्टमी के दिन व्रत कर, श्रद्धा पूर्वक ध्यावे।\nसन्तोषी माता जी, भक्तन सुख पावे॥\nजय सन्तोषी माता, मैया जय सन्तोषी माता।\nअपने सेवक जन की, सुख सम्पत्ति दाता॥',
      ],
    ),
  ];

  /// Find an aarti by id; falls back to the first one.
  static Aarti byId(String id) {
    return aartis.firstWhere(
      (a) => a.id == id,
      orElse: () => aartis.first,
    );
  }
}
