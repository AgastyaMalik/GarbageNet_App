import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pytorch_lite/pytorch_lite.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:webview_flutter/webview_flutter.dart';
void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GarbageNet App',
      theme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.deepPurple,
        scaffoldBackgroundColor: Colors.black,
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Colors.white, fontSize: 16),
        ),
      ),
      home: const MyHomePage(title: 'GarbageNet'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _selectedIndex = 0;

  File? _image;
  String? _predictionClass;
  String? _imagePrediction;
  String? _disposalInstruction;
  Color? _predictionColor;
  final ImagePicker _picker = ImagePicker();

  static List<Widget> _widgetOptions = <Widget>[
    HomeContent(),
    AwarenessEducationPage(),
    WasteSegregationTipsPage(),
    RecyclingCentreInfoPage(), // New page for Recycling Centre Information
    ReportAndComplaintPage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Future<void> _getImage(ImageSource source) async {
    try {
      final pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 80, // Adjust image quality as needed
      );
      if (pickedFile != null) {
        setState(() {
          _image = File(pickedFile.path);
        });
      }
    } catch (e) {
      print('Error picking image: $e');
      // Handle error
    }
  }

  Future<void> _classifyImage(File imageFile) async {
    try {
      ClassificationModel classificationModel = await PytorchLite.loadClassificationModel(
        "android/assets/model/GarbageNetMobile.pt",
        224,
        224,
        10,
        labelPath: 'android/assets/model/labels.txt',
      );

      String imagePrediction =
          (await classificationModel.getImagePrediction(await imageFile.readAsBytes())).trim().toLowerCase();

      // Debugging print statements
      print('Image Prediction: $imagePrediction');

      // Define detailed disposal instructions
      Map<String, String> disposalInstructions = {
        'battery':
            'Dispose of batteries at designated battery recycling points. Many retailers and municipal waste programs have specific battery recycling containers. Do not throw batteries in regular trash as they contain harmful chemicals.',
        'biological':
            'Dispose of biological waste by placing it in a biodegradable bag and then in a dedicated compost bin or green waste container. Ensure that the composting facility accepts biological waste. Never dispose of biological waste in regular trash or recycling bins.',
        'cardboard':
            'Flatten cardboard boxes and remove any non-paper packaging materials (e.g., plastic, foam). Place the flattened cardboard in the recycling bin. If the cardboard is heavily soiled (e.g., with grease or food), compost it if possible or dispose of it in the trash.',
        'clothes':
            'Donate gently used clothes to charity organizations, thrift stores, or textile recycling programs. For clothes that are not in good condition, consider repurposing them as cleaning rags or taking them to textile recycling centers.',
        'glass':
            'Rinse glass containers to remove food residue and remove any lids or caps. Place the clean glass in the recycling bin. Do not include broken glass, light bulbs, or glassware (e.g., Pyrex) in the recycling; check with your local waste management program for specific disposal instructions.',
        'metal':
            'Rinse metal containers to remove food residue and place them in the recycling bin. For larger metal items (e.g., appliances), contact your local recycling center or scrap metal facility. Do not include aerosol cans unless they are completely empty.',
        'paper':
            'Place clean and dry paper products (e.g., newspapers, magazines, office paper) in the recycling bin. Shredded paper can be recycled, but it should be placed in a clear plastic bag or paper bag before being placed in the recycling bin.',
        'plastic':
            'Rinse plastic containers to remove food residue and check for recycling symbols (typically numbers 1-7) to determine if they are accepted by your local recycling program. Place accepted plastics in the recycling bin. Do not include plastic bags, wraps, or films unless your local program specifies otherwise; these can often be recycled at designated drop-off locations.',
        'shoes':
            'Donate gently used shoes to charity organizations or shoe recycling programs. For shoes that are no longer wearable, check for recycling programs that accept shoes. Some brands offer take-back programs for their products.',
        'trash':
            'Place non-recyclable, non-compostable items in the trash bin. Ensure that hazardous materials (e.g., batteries, chemicals) are not included. Regular trash typically goes to landfills or incineration facilities, so minimizing trash by recycling and composting when possible is beneficial.'
      };

      // Define colors for each prediction
      Map<String, Color> predictionColors = {
        'battery': Colors.orange,
        'biological': Colors.lightGreen,
        'cardboard': Colors.brown,
        'clothes': Colors.red,
        'glass': Colors.green,
        'metal': Colors.yellow,
        'paper': Colors.blue,
        'plastic': Colors.purple,
        'shoes': Colors.pink,
        'trash': Colors.white,
      };

      // Determine prediction class and color
      String predictionClass;
      Color? predictionColor;
      if (['cardboard', 'paper', 'glass', 'battery', 'metal'].contains(imagePrediction)) {
        predictionClass = "Recyclable";
      } else if (['plastic', 'clothes', 'shoes'].contains(imagePrediction)) {
        predictionClass = "Reusable";
      } else if (['trash', 'biological'].contains(imagePrediction)) {
        predictionClass = "Disposable";
      } else {
        predictionClass = "Unknown";
      }

      predictionColor = predictionColors[imagePrediction];

      print('Prediction Class: $predictionClass');

      setState(() {
        _predictionClass = predictionClass;
        _imagePrediction = imagePrediction;
        _disposalInstruction = disposalInstructions[imagePrediction];
        _predictionColor = predictionColor;
      });

    } catch (e) {
      print('Error classifying image: $e');
      // Handle error (e.g., show an error message)
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      
      body: Row(
        children: <Widget>[
          NavigationRail(
  selectedIndex: _selectedIndex,
  onDestinationSelected: _onItemTapped,
  labelType: NavigationRailLabelType.all,
  destinations: const <NavigationRailDestination>[
    NavigationRailDestination(
      icon: Icon(Icons.home),
      label: Text('Home'),
    ),
    NavigationRailDestination(
      icon: Icon(Icons.school),
      label: Text('Awareness'),
    ),
    NavigationRailDestination(
      icon: Icon(Icons.lightbulb_outline),
      label: Text('Waste Segregation'),
    ),
    NavigationRailDestination(
      icon: Icon(Icons.public),
      label: Text('Recycling Centres'),
    ),
    NavigationRailDestination(
      icon: Icon(Icons.report),
      label: Text('Report'), // Add this line
    ),
  ],
),
          VerticalDivider(thickness: 1, width: 1),
          // This is the main content.
          Expanded(
            child: _selectedIndex == 0
                ? HomeContent(
                    image: _image,
                    predictionClass: _predictionClass,
                    imagePrediction: _imagePrediction,
                    disposalInstruction: _disposalInstruction,
                    predictionColor: _predictionColor,
                    getImage: _getImage,
                    classifyImage: _classifyImage,
                  )
                : _widgetOptions.elementAt(_selectedIndex),
          ),
        ],
      ),
    );
  }
}

class HomeContent extends StatelessWidget {
  const HomeContent({
    Key? key,
    this.image,
    this.predictionClass,
    this.imagePrediction,
    this.disposalInstruction,
    this.predictionColor,
    this.getImage,
    this.classifyImage,
  }) : super(key: key);

  final File? image;
  final String? predictionClass;
  final String? imagePrediction;
  final String? disposalInstruction;
  final Color? predictionColor;
  final Function(ImageSource)? getImage;
  final Function(File)? classifyImage;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Text(
            'Classify Waste', // Added heading
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 16),
          image != null ? Image.file(image!) : const Text('No image selected.'),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => getImage?.call(ImageSource.gallery),
            child: const Text('Upload Image'),
          ),
          ElevatedButton(
            onPressed: () => getImage?.call(ImageSource.camera),
            child: const Text('Take Photo'),
          ),
          ElevatedButton(
            onPressed: () {
              if (image != null) {
                classifyImage?.call(image!);
              } else {
                print('No image selected to classify.');
              }
            },
            child: const Text('Classify Image'),
          ),
          if (predictionClass != null && imagePrediction != null)
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Prediction Class: $predictionClass',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      RichText(
                        text: TextSpan(
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                          ),
                          children: [
                            const TextSpan(text: 'Image Prediction: '),
                            TextSpan(
                              text: imagePrediction!,
                              style: TextStyle(
                                color: predictionColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (disposalInstruction != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 16.0),
                          child: Text(
                            'Disposal Instructions: $disposalInstruction',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.white,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class AwarenessEducationPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Center(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: Text(
                'Educational Resources, Interactive Tutorials, and Guidelines on Waste Management Practices',
                style: Theme.of(context).textTheme.titleLarge!.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 16),
            _buildSection(
              context,
              'Online Platforms and Websites',
              [
                _buildResourceLink(
                  context,
                  'Environmental Protection Agency (EPA)',
                  Uri.parse('https://www.epa.gov/waste'),
                  'Offers comprehensive guides and resources on waste management practices.',
                ),
                _buildResourceLink(
                  context,
                  'World Health Organization (WHO)',
                  Uri.parse('https://www.who.int/health-topics/environmental-health'),
                  'Provides guidelines on environmental health and sustainable practices.',
                ),
                _buildResourceLink(
                  context,
                  'National Geographic',
                  Uri.parse('https://www.nationalgeographic.com/environment/article/recycling-resources'),
                  'Features articles and interactive tools on recycling and waste reduction.',
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildSection(
              context,
              'Mobile Apps',
              [
                _buildResourceLink(
                  context,
                  'Recycle Coach App',
                  Uri.parse('https://recyclecoach.com/'),
                  'Helps users learn about local recycling options and provides recycling tips.',
                ),
                _buildResourceLink(
                  context,
                  'iRecycle App',
                  Uri.parse('https://irecycleapp.com/'),
                  'Offers information on how and where to recycle various items.',
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildSection(
              context,
              'Educational Videos',
              [
                _buildResourceLink(
                  context,
                  'Earth911 YouTube Channel',
                  Uri.parse('https://www.youtube.com/user/Earth911TV'),
                  'Dedicated to environmental education and waste management.',
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildSection(
              context,
              'Books and Publications',
              [
                _buildResourceLink(
                  context,
                  'Silent Spring by Rachel Carson',
                  Uri.parse('https://www.amazon.com/Silent-Spring-Rachel-Carson/dp/0618249060'),
                  'A pioneering book on the environmental impact of pesticides.',
                ),
                _buildResourceLink(
                  context,
                  'Cradle to Cradle by William McDonough and Michael Braungart',
                  Uri.parse('https://www.amazon.com/Cradle-Remaking-Way-Make-Things/dp/0865475873'),
                  'Explores sustainable design principles and waste reduction strategies.',
                ),
                _buildResourceLink(
                  context,
                  'The Sixth Extinction by Elizabeth Kolbert',
                  Uri.parse('https://www.amazon.com/Sixth-Extinction-Unnatural-History/dp/1250062187'),
                  'Examines the current biodiversity crisis and human impact on the environment.',
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildSection(
              context,
              'Interactive Websites and Tools',
              [
                _buildResourceLink(
                  context,
                  'Recycle Now (UK)',
                  Uri.parse('https://www.recyclenow.com/'),
                  'Provides interactive tools and resources for understanding and managing waste.',
                ),
                _buildResourceLink(
                  context,
                  'Recycle.org',
                  Uri.parse('https://www.recycle.org/'),
                  'Offers tools to calculate your carbon footprint and find ways to reduce waste.',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, List<Widget> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleMedium!.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: items,
        ),
      ],
    );
  }

  Widget _buildResourceLink(BuildContext context, String title, Uri link, String description) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => _launchURL(link),
            child: Text(
              title,
              style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.blueAccent,
                    decoration: TextDecoration.underline,
                  ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                  color: Colors.white,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            'Link: $link',
            style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                  color: Colors.white,
                ),
          ),
        ],
      ),
    );
  }

  void _launchURL(Uri url) async {
     
    try{
      if (await canLaunchUrl(url)) {
        await launchUrl(url);
      } else {
        throw 'Could not launch $url';
      }
    }
    catch(e){
      print("exception in launc url");
    }
  }
}

class WasteSegregationTipsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Waste Segregation Tips'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Comprehensive Guide to Waste Segregation',
              style: Theme.of(context).textTheme.titleLarge!.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
            ),
            const SizedBox(height: 16.0),
            _buildWasteTypesSection(context),
            const SizedBox(height: 16.0),
            _buildBestPracticesSection(context),
            const SizedBox(height: 16.0),
            _buildBenefitsSection(context),
            const SizedBox(height: 16.0),
            _buildConclusion(context),
          ],
        ),
      ),
    );
  }

  Widget _buildWasteTypesSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Types of Waste',
          style: Theme.of(context).textTheme.titleMedium!.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
        ),
        const SizedBox(height: 12.0),
        _buildWasteType(
          context,
          'Biodegradable Waste',
          'Includes organic materials like food scraps, garden waste, and biodegradable packaging.',
          'Segregation Tip: Use compost bins for organic waste to create compost for gardens or farms.',
        ),
        const SizedBox(height: 8.0),
        _buildWasteType(
          context,
          'Recyclable Waste',
          'Includes materials such as paper, cardboard, glass, metal cans, and certain plastics (marked with recycling symbols).',
          'Segregation Tip: Separate recyclable materials into designated recycling bins provided by your local waste management.',
        ),
        const SizedBox(height: 8.0),
        _buildWasteType(
          context,
          'Hazardous Waste',
          'Includes batteries, electronics, chemicals, and items containing toxic substances.',
          'Segregation Tip: Dispose of hazardous waste at designated collection points to prevent environmental contamination.',
        ),
        const SizedBox(height: 8.0),
        _buildWasteType(
          context,
          'Non-Recyclable Waste',
          'Includes items that cannot be recycled, such as plastic wrappers, styrofoam, and heavily contaminated materials.',
          'Segregation Tip: Place non-recyclable waste in regular waste bins for proper disposal.',
        ),
        const SizedBox(height: 8.0),
        _buildWasteType(
          context,
          'Construction and Demolition Waste',
          'Includes debris, concrete, wood, and other materials from construction or renovation projects.',
          'Segregation Tip: Separate these materials for recycling or responsible disposal at construction waste recycling centers.',
        ),
      ],
    );
  }

  Widget _buildWasteType(BuildContext context, String title, String description, String tip) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleSmall!.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
        ),
        const SizedBox(height: 4.0),
        Text(
          description,
          style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                color: Colors.white,
              ),
        ),
        const SizedBox(height: 4.0),
        Text(
          tip,
          style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                fontStyle: FontStyle.italic,
                color: Colors.grey,
              ),
        ),
      ],
    );
  }

  Widget _buildBestPracticesSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Best Practices for Waste Segregation',
          style: Theme.of(context).textTheme.titleMedium!.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
        ),
        const SizedBox(height: 12.0),
        _buildBestPractice(
          context,
          'Educate and Label',
          'Clearly label bins for different types of waste to facilitate correct segregation by residents and visitors.',
        ),
        const SizedBox(height: 8.0),
        _buildBestPractice(
          context,
          'Minimize Contamination',
          'Rinse recyclable materials like glass jars and aluminum cans to reduce contamination.',
        ),
        const SizedBox(height: 8.0),
        _buildBestPractice(
          context,
          'Follow Local Guidelines',
          'Adhere to local waste management regulations and guidelines for proper disposal and recycling practices.',
        ),
        const SizedBox(height: 8.0),
        _buildBestPractice(
          context,
          'Encourage Participation',
          'Promote community engagement and awareness through educational campaigns and incentives for proper waste segregation.',
        ),
      ],
    );
  }

  Widget _buildBestPractice(BuildContext context, String title, String description) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
        ),
        const SizedBox(height: 4.0),
        Text(
          description,
          style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                color: Colors.white,
              ),
        ),
      ],
    );
  }

  Widget _buildBenefitsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Benefits of Proper Waste Segregation',
          style: Theme.of(context).textTheme.titleMedium!.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
        ),
        const SizedBox(height: 12.0),
        _buildBenefit(
          context,
          'Environmental Protection',
          'Reduces landfill waste and promotes recycling, conserving natural resources.',
        ),
        const SizedBox(height: 8.0),
        _buildBenefit(
          context,
          'Cost Efficiency',
          'Improves efficiency in waste management processes and reduces disposal costs.',
        ),
        const SizedBox(height: 8.0),
        _buildBenefit(
          context,
          'Health and Safety',
          'Minimizes risks associated with hazardous waste exposure and environmental pollution.',
        ),
      ],
    );
  }

  Widget _buildBenefit(BuildContext context, String title, String description) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
        ),
        const SizedBox(height: 4.0),
        Text(
          description,
          style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                color: Colors.white,
              ),
        ),
      ],
    );
  }

  Widget _buildConclusion(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Conclusion',
          style: Theme.of(context).textTheme.titleMedium!.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
        ),
        const SizedBox(height: 12.0),
        Text(
          'By implementing proper waste segregation practices, individuals and communities can contribute significantly to environmental conservation and sustainable development. Consistent efforts in waste segregation support recycling initiatives and promote a cleaner, healthier environment for future generations.',
          style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                color: Colors.white,
              ),
        ),
      ],
    );
  }
}

class RecyclingCentreInfoPage extends StatelessWidget {
  final List<Map<String, dynamic>> recyclingCenters = [
    {
      'name': 'Green-O-Tech',
      'address': 'Raghu Nagar Near Janak Cinema, New Delhi',
      'services': 'Plastic waste: PET, Paper, wood',
      'website': 'greenotechindia.com',
      'phone': '78400 24848, 78400 34848',
      'email': 'info@greenotech.in',
    },
    {
      'name': 'Dumpin Recyclers Pvt. Ltd.',
      'address': 'New Delhi, 110096 India',
      'services': 'Plastic, paper, metal',
      'website': 'dumpin.in',
      'phone': '9582118311',
      'email': 'contact@dumpin.in',
    },
    {
      'name': 'Chintan PickMyTrash',
      'address': 'C-14, Lajpat Nagar III, Second Floor, New Delhi, India - 110024',
      'services': 'Plastic, paper, cartons, metals, tetrapacks',
      'website': 'chintan-india.org',
      'phone': '180030007969, +91-11-2984 2809, +91-11-4657 4172',
      'email': 'info@chintan-india.org',
    },
    {
      'name': 'Pom Pom',
      'address': 'F 27/2, First Floor, Okhla Phase II, Okhla Industrial Area',
      'services': 'Paper, Plastic, Glass & Metal categories',
      'phone': '91 95997 81512',
    },
    {
      'name': 'AllScrap Waste Management Services',
      'address': '336 AH NEAR ROCK GARDEN MUNIRKA DELHI',
      'services': 'All',
      'website': 'allscrap.org',
      'phone': '09711963469',
      'email': 'info@allscrap.org',
    },
    {
      'name': 'Karma Recycling',
      'address': '971/1 Kapashera, (opposite Fun n Food Village), Delhi/NCR',
      'services': 'E-waste recycling',
      'website': 'karmarecycling.in',
      'phone': '847-006-3726',
      'email': 'hello@karmarecycling.in',
    },
    {
      'name': 'Dumpster',
      'address': 'No. 6, Ground Floor, Block-B, Uttam Nagar, Najafgarh Road, Sewak Park, Near Metro Pillar no. 760 New Delhi – 110059',
      'services': 'Converting Paper Waste To Recycled Stationary',
      'website': 'dumpterre.com',
      'phone': '91-8826452502, +91-9999714998',
      'email': 'dumpsterre@gmail.com',
    },
    {
      'name': 'All India Recycle Network ( Recycling Guide)',
      'address': 'Office: F-1, LGF, Jal Vihar Road, Lajpat Nagar-1, New Delhi – 110024',
      'services': 'Recycling Guide',
      'website': 'allindiarecyclingnetwork.com',
      'phone': '91 9899007201, 91 11 29825041',
      'email': 'raksol@gmail.com',
    },
    {
      'name': 'JAAGRUTI',
      'address': 'Delhi, Delhi',
      'services': 'Waste Paper Recycling Services',
      'website': 'we-recycle.org',
      'phone': '91-98101 91625, +91-9818 144 244',
      'email': 'paper@we-recycle.org, contact@jaagruti.org',
    },
    {
      'name': 'Recycler App',
      'address': 'Green Park, New Delhi',
      'services': 'Plastic and e-waste',
      'website': 'recyclerapp.com',
      'phone': '9015069606',
      'email': 'therecycler.app@gmail.com',
    },
    {
      'name': 'Exigo Recycling Pvt Ltd',
      'address': 'G-18 GROUND FLOOR,VISHWAKARMA COLONY,PRAHLADPUR,NEW DELHI 110044',
      'services': 'E-Waste Removal / IT Assets Decommissioning, CFL Recycling',
      'website': 'exigorecycling.in',
      'phone': '1800 1025 018',
      'email': 'amit.lavaniyan@bizlog.in',
    },
    {
      'name': 'Exigo Recycling Pvt Ltd',
      'address': 'D-226, Sec-10, Noida-201301, Delhi/NCR',
      'services': 'E-Waste Removal / IT Assets Decommissioning, CFL Recycling',
      'website': 'exigorecycling.in',
      'phone': '1800 1025 018',
      'email': 'amit.lavaniyan@bizlog.in',
    },
    {
      'name': 'Exigo Recycling Pvt Ltd',
      'address': '72km Stone, NH1 (NCR), Next to Maruti Showroom, Samalkha, Haryana - 132101',
      'services': 'E-Waste Removal / IT Assets Decommissioning, CFL Recycling',
      'website': 'exigorecycling.in',
      'phone': '1800 1025 018',
      'email': 'sachinbajaj@exigorecycling.com',
    },
    {
      'name': 'Exigo Recycling Pvt Ltd',
      'address': 'C-3 ASHIANA PATLIPUTRA ROAD JAI PRAKASH NAGAR, Patna-800025, Bihar',
      'services': 'E-Waste Removal / IT Assets Decommissioning, CFL Recycling',
      'website': 'exigorecycling.in',
      'phone': '1800 1025 018',
      'email': 'patnaops@bizlog.in',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Recycling Centres'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'More recycling centres: https://www.zoobop.com/recycle-center.aspx ',
              style: TextStyle(color: Colors.blue),
            ),
            const SizedBox(height: 8),
            _buildRecyclingCentres(context),
          ],
        ),
      ),
    );
  }

  Widget _buildRecyclingCentres(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: recyclingCenters.length,
      itemBuilder: (context, index) {
        final center = recyclingCenters[index];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8.0),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  center['name'],
                  style: Theme.of(context).textTheme.titleMedium!.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(center['address']),
                const SizedBox(height: 8),
                if (center['services'] != null) Text('Services: ${center['services']}'),
                const SizedBox(height: 8),
                if (center['website'] != null) Text('Website: ${center['website']}'),
                if (center['phone'] != null) Text('Phone: ${center['phone']}'),
                if (center['email'] != null) Text('Email: ${center['email']}'),
              ],
            ),
          ),
        );
      },
    );
  }
}
  final List<Map<String, dynamic>> recyclingCenters = [
    {
      'name': 'Green-O-Tech',
      'address': 'Raghu Nagar Near Janak Cinema, New Delhi',
      'services': 'Plastic waste: PET, Paper, wood',
      'website': 'greenotechindia.com',
      'phone': '78400 24848, 78400 34848',
      'email': 'info@greenotech.in',
    },
    {
      'name': 'Dumpin Recyclers Pvt. Ltd.',
      'address': 'New Delhi, 110096 India',
      'services': 'Plastic, paper, metal',
      'website': 'dumpin.in',
      'phone': '9582118311',
      'email': 'contact@dumpin.in',
    },
    {
      'name': 'Chintan PickMyTrash',
      'address': 'C-14, Lajpat Nagar III, Second Floor, New Delhi, India - 110024',
      'services': 'Plastic, paper, cartons, metals, tetrapacks',
      'website': 'chintan-india.org',
      'phone': '180030007969, +91-11-2984 2809, +91-11-4657 4172',
      'email': 'info@chintan-india.org',
    },
    {
      'name': 'Pom Pom',
      'address': 'F 27/2, First Floor, Okhla Phase II, Okhla Industrial Area',
      'services': 'Paper, Plastic, Glass & Metal categories',
      'phone': '91 95997 81512',
    },
    {
      'name': 'AllScrap Waste Management Services',
      'address': '336 AH NEAR ROCK GARDEN MUNIRKA DELHI',
      'services': 'All',
      'website': 'allscrap.org',
      'phone': '09711963469',
      'email': 'info@allscrap.org',
    },
    {
      'name': 'Karma Recycling',
      'address': '971/1 Kapashera, (opposite Fun n Food Village), Delhi/NCR',
      'services': 'E-waste recycling',
      'website': 'karmarecycling.in',
      'phone': '847-006-3726',
      'email': 'hello@karmarecycling.in',
    },
    {
      'name': 'Dumpster',
      'address': 'No. 6, Ground Floor, Block-B, Uttam Nagar, Najafgarh Road, Sewak Park, Near Metro Pillar no. 760 New Delhi – 110059',
      'services': 'Converting Paper Waste To Recycled Stationary',
      'website': 'dumpterre.com',
      'phone': '91-8826452502, +91-9999714998',
      'email': 'dumpsterre@gmail.com',
    },
    {
      'name': 'All India Recycle Network ( Recycling Guide)',
      'address': 'Office: F-1, LGF, Jal Vihar Road, Lajpat Nagar-1, New Delhi – 110024',
      'services': 'Recycling Guide',
      'website': 'allindiarecyclingnetwork.com',
      'phone': '91 9899007201, 91 11 29825041',
      'email': 'raksol@gmail.com',
    },
    {
      'name': 'JAAGRUTI',
      'address': 'Delhi, Delhi',
      'services': 'Waste Paper Recycling Services',
      'website': 'we-recycle.org',
      'phone': '91-98101 91625, +91-9818 144 244',
      'email': 'paper@we-recycle.org, contact@jaagruti.org',
    },
    {
      'name': 'Recycler App',
      'address': 'Green Park, New Delhi',
      'services': 'Plastic and e-waste',
      'website': 'recyclerapp.com',
      'phone': '9015069606',
      'email': 'therecycler.app@gmail.com',
    },
    {
      'name': 'Exigo Recycling Pvt Ltd',
      'address': 'G-18 GROUND FLOOR,VISHWAKARMA COLONY,PRAHLADPUR,NEW DELHI 110044',
      'services': 'E-Waste Removal / IT Assets Decommissioning, CFL Recycling',
      'website': 'exigorecycling.in',
      'phone': '1800 1025 018',
      'email': 'amit.lavaniyan@bizlog.in',
    },
    {
      'name': 'Exigo Recycling Pvt Ltd',
      'address': 'D-226, Sec-10, Noida-201301, Delhi/NCR',
      'services': 'E-Waste Removal / IT Assets Decommissioning, CFL Recycling',
      'website': 'exigorecycling.in',
      'phone': '1800 1025 018',
      'email': 'amit.lavaniyan@bizlog.in',
    },
    {
      'name': 'Exigo Recycling Pvt Ltd',
      'address': '72km Stone, NH1 (NCR), Next to Maruti Showroom, Samalkha, Haryana - 132101',
      'services': 'E-Waste Removal / IT Assets Decommissioning, CFL Recycling',
      'website': 'exigorecycling.in',
      'phone': '1800 1025 018',
      'email': 'sachinbajaj@exigorecycling.com',
    },
    {
      'name': 'Exigo Recycling Pvt Ltd',
      'address': 'C-3 ASHIANA PATLIPUTRA ROAD JAI PRAKASH NAGAR, Patna-800025, Bihar',
      'services': 'E-Waste Removal / IT Assets Decommissioning, CFL Recycling',
      'website': 'exigorecycling.in',
      'phone': '1800 1025 018',
      'email': 'patnaops@bizlog.in',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Recycling Centre Information'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: Text(
                'Recycling Centres in India',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            Text(
              'visit https://www.zoobop.com/recycle-center.aspx',
              style: TextStyle(color: Colors.blue),
            ),
            const SizedBox(height: 8),
            _buildRecyclingCentres(context),
          ],
        ),
      ),
    );
  }

  Widget _buildRecyclingCentres(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: recyclingCenters.length,
      itemBuilder: (context, index) {
        final center = recyclingCenters[index];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8.0),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  center['name'],
                  style: Theme.of(context).textTheme.titleMedium!.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(center['address']),
                const SizedBox(height: 8),
                if (center['services'] != null) Text('Services: ${center['services']}'),
                const SizedBox(height: 8),
                if (center['website'] != null) Text('Website: ${center['website']}'),
                if (center['phone'] != null) Text('Phone: ${center['phone']}'),
                if (center['email'] != null) Text('Email: ${center['email']}'),
              ],
            ),
          ),
        );
      },
    );
  }


class ReportAndComplaintPage extends StatelessWidget {
  const ReportAndComplaintPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    WebViewController webViewController = WebViewController();

    return Scaffold(
        appBar: AppBar(),
        body: WebViewWidget(
            controller: webViewController
              ..loadRequest(Uri.parse('https://pwdsewa.pwddelhi.gov.in/Home/SubmitComplaint/'))));
  }
}

class WebViewApp extends StatefulWidget {
  const WebViewApp({super.key});

  @override
  State<WebViewApp> createState() => _WebViewAppState();
}

class _WebViewAppState extends State<WebViewApp> {
  late final WebViewController controller;

  @override
  void initState() {
    super.initState();
    controller = WebViewController()
      ..loadRequest(
        Uri.parse('https://pwdsewa.pwddelhi.gov.in/Home/SubmitComplaint/'),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Flutter WebView'),
      ),
      body: WebViewWidget(
        controller: controller,
      ),
    );
  }
}
class FadeIn extends StatelessWidget {
  final Widget child;
  final Duration duration;

  const FadeIn({
    Key? key,
    required this.child,
    this.duration = const Duration(milliseconds: 500),
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: duration,
      builder: (context, double opacity, child) {
        return Opacity(opacity: opacity, child: child);
      },
      child: child,
    );
  }
}