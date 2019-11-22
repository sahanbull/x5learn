from time import sleep
from os import system


# terms = [ 'Supervised learning', 'Linear Regression', 'Logistic Regression', 'Regularization', 'Bias vs Variance tradeoff', 'Unsupervised Learning', 'K-Means Algorithm', 'Dimensionality Reduction', 'Principal Component Analysis', 'Anamoly Detection', 'Recommender Systems', 'Outliers', 'Problem of Underfitting and Overfitting', 'The Bias-Variance trade-off', 'Intro to jupyter notebooks', 'Data Science packages', 'Regression Analysis', 'What is Regression Analysis', 'Linear Regression', 'Cost Function', 'Gradient Descent', 'Polynomial Regression', 'Logistic Regression', 'Cost Function for Logistic Regression', 'Regularization', 'Evaluating a Machine Learning Model', 'Bayesian Statistics', 'Introduction to Conditional Probability', 'Bayes Rule', 'Bayesian Learning', 'Naïve Bayes Algorithm', 'Test your understanding of Bayes Theorem', 'Solution – Test Your Understanding of Bayes Theorem', 'Bayes Net', 'Markov Chains', 'Tree-Based Learning', 'Decision Trees', 'Gini Index', 'ID3 Algorithm – Entropy', 'ID3 Algorithm – Information Gain', 'Practice Example – Information Gain', 'House Price Predictions', 'Spam Classifier', 'Ensemble Learning', 'What is Ensemble Learning', 'Bagging', 'Random Forest Algorithm', 'Boosting', 'Support Vector Machines', 'Introduction to Support Vector Machines', 'Support Vectors', 'Kernel', 'Hyperparameters in SVMs', 'Instance Based Learning & Feature Engineering', 'What is Instance Based Learning', 'K-Nearest Neighbours Algorithm', 'Dimensionality Reduction', 'Principle Component Analysis', 'Feature Scaling', 'K-Means Algorithm', 'Breast Cancer Prediction', 'Deep Learning', 'Introduction to Deep Learning', 'Perceptron', 'Perceptron Exercise', 'Solution – Perceptron Exercise', 'Deep Neural Networks', 'Deep Neural Networks', 'Activation Functions', 'Backpropagation Algorithm', 'Convolutional Neural Nets' ]

# terms = [ 'adaptation', 'additionality', 'albedo', 'anoxic_event', 'antarctic_bottom_water_(abw)', 'antarctic_oscillation_(aao)', 'antarctica_cooling_controversy', 'anthropogenic', 'anthropogenic_climate_change', 'anthropogenic_global_warming_(agw)', 'anti-greenhouse_effect', 'arctic_amplification', 'arctic_dipole_anomaly', 'arctic_oscillation_(ao)', 'arctic_shrinkage', 'argo', 'atlantic_multidecadal_oscillation_(amo)', 'atmospheric_sciences', 'atmospheric_window', 'attribution_of_recent_climate_change', 'blytt-sernander_sequence', 'bond_events', 'callendar_effect', 'cap_and_trade', 'carbon_cycle', 'carbon_diet', 'carbon_dioxide', 'carbon_footprint', 'carbon_offset', 'carbon_sequestration', 'carbon_sink', 'carbon_tax', 'clathrate_gun_hypothesis', 'climate', 'climate_change', 'climate_change_denial', 'climate_change_feedback', 'climate_commitment', 'climate_cycle', 'climate_ethics', 'climate_forcing', 'climate_justice', 'climate_legislation', 'climate_model', 'climate_movement', 'climate_oscillation', 'climate_resilience', 'climate_sensitivity', 'climate_stabilization_wedge', 'climate_system', 'climate_variability', 'climatology', 'cool_tropics_paradox', 'cosmic_rays', 'dendroclimatology', 'desertification', 'detection_and_attribution', 'eco-efficiency', 'earth&#39;s_atmosphere', 'earthshine', 'ecotax', 'ecosystem_services', 'el_niño-southern_oscillation_(enso)', 'emission_intensity', 'emission_inventory', 'emission_standards', 'emissions_trading', 'enteric_fermentation', 'environmental_crime', 'environmental_migrant', 'feedback', 'forest_dieback', 'fossil_fuel', 'freon', 'glacial_earthquake', 'glacial_motion', 'global_cooling', 'global_climate_model_(gcm)', 'global_climate_regime', 'global_dimming', 'global_warming_(gw)', 'global_warming_controversy', 'global_warming_denial', 'global_warming_period', 'global_warming_potential', 'greenhouse_debt', 'greenhouse_effect', 'greenhouse_gas', 'greenhouse_gas_inventory', 'gulf_stream', 'heiligendamm_process', 'historical_temperature_record', 'hockey_stick_graph', 'hockey_stick_controversy', 'holocene', 'holocene_climatic_optimum', 'homogenization', 'ice_age', 'ice_core', 'insolation', 'invasive_species', 'iris_hypothesis', 'irradiance', 'instrumental_temperature_record', 'interdecadal_pacific_oscillation_(ipo)', 'intergovernmental_panel_on_climate_change_(ipcc)', 'keeling_curve', 'kyoto_protocol', 'little_ice_age', 'magnetosphere', 'maunder_minimum', 'mauna_loa', 'medieval_warm_period', 'meteorology', 'methane', 'milankovitch_cycles', 'mitigation_of_global_warming', 'mode_of_variability', 'nitrous_oxide', 'nonradiative_forcing', 'north_atlantic_deep_water', 'north_atlantic_oscillation', 'ocean_planet', 'orbital_forcing', 'ozone', 'ozone_depletion', 'ozone_layer', 'pacific_decadal_oscillation_(pdo)', 'paleocene–eocene_thermal_maximum_(petm)', 'paleoclimatology', 'phenology', 'polar_amplification', 'polar_city', 'proxy', 'radiative_forcing', 'regime_shift', 'removal_unit', 'runaway_greenhouse_effect', 'sea_level_rise', 'season_creep', 'slash_and_burn', 'snowball_earth', 'solar_variation', 'solar_wind', 'stranded_asset', 'stratospheric_sulfur_aerosol', 'sunspot', 'thermohaline_circulation', 'tex-86', 'thermocline', 'tipping_points_in_the_climate_system', 'urban_heat_island', 'volcanism', 'water_vapor', 'weather', 'world_climate_report']

# terms = [ 'action potential', 'addiction', 'adrenal glands', 'adrenaline', 'allele', 'Alzheimer’s disease', 'amino acid', 'amino acid neurotransmitters', 'amygdala', 'amyloid-beta (Aβ) protein', 'amyloid plaque', 'amyotrophic lateral sclerosis (ALS)', 'angiography', 'animal model', 'antidepressant medication', 'anxiety', 'apoptosis', 'artificial intelligence (AI)', 'astrocyte', 'attention deficit hyperactivity disorder (ADHD)', 'auditory cortex', 'autism spectrum disorder (ASD)', 'autonomic nervous system', 'axon', 'axon terminal', 'basal ganglia', 'basilar artery', 'biomarkers', 'bipolar disorder', 'blood-brain barrier', 'brain-computer interface', 'brain-derived neurotrophic factor (BDNF)', 'brain imaging', 'brain stem', 'brain tumor', 'brain waves', 'Broca’s area', 'cell body', 'central nervous system', 'central sulcus', 'cerebellar artery', 'cerebellum', 'cerebral palsy', 'cerebrospinal fluid (CSF)', 'cerebrum', 'chromosome', 'chronic encephalopathy syndrome (CES)', 'chronic traumatic encephalopathy (CTE)', 'cochlea', 'cognition', 'cognitive neuroscience', 'computational neuroscience', 'computed tomography (CT or CAT)', 'concussion', 'cone', 'connectome', 'consciousness', 'corpus callosum', 'cortex', 'cortisol', 'critical period', 'CRISPR (clustered regularly-interspaced short palindromic repeats)', 'deep brain stimulation', 'deep learning', 'default-mode network', 'dementia', 'dendrites', 'depression', 'Diagnostic and Statistical Manual of Mental Disorders (DSM)', 'diffusion spectrum imaging (DSI)', 'diffusion tensor imaging (DTI)', 'DNA (deoxyribonucleic acid)', 'digital phenotyping', 'dominant gene', 'dopamine', 'double helix', 'Down syndrome', 'dyslexia', 'electroencephalography (EEG)', 'electroconvulsive therapy (ECT)', 'endocrine system', 'endorphins', 'enzyme', 'epigenetics', 'epilepsy', 'executive function', 'fissure', 'Fragile X syndrome', 'frontal lobe', 'frontal operculum', 'frontotemporal degeneration (FTD)', 'functional magnetic resonance imaging (fMRI)', 'gamma-aminobutyric acid (GABA)', 'gene', 'gene expression', 'gene mapping', 'genome', 'glia (or glial cells)', 'glioblastoma', 'glioma', 'glucose', 'glymphatic system', 'gray matter', 'gyrus', 'hemisphere', 'hippocampus', 'hormone', 'Huntington’s disease', 'hypothalamus', 'in silico', 'in vitro', 'in vivo', 'induced pluripotent stem cell (iPSC)', 'insula', 'ions', 'ion channel', 'ketamine', 'lesion', 'limbic system', 'long term potentiation (LTP)', 'Lou Gehrig’s disease', 'machine learning', 'magnetic resonance imaging (MRI)', 'manic-depressive disorder', 'medulla oblongata', 'melatonin', 'memory', 'mental health', 'mesolimbic circuit', 'mesolimbic pathway', 'metabolize', 'microbiota', 'microglia', 'midbrain', 'minimally conscious state', 'molecular biology', 'mood', 'motor cortex', 'multiple sclerosis', 'mutation', 'myelin', 'narcotic', 'nerve growth factor', 'nerve cell', 'nerve impulse', 'nervous system', 'neuroeconomics', 'neurodegenerative diseases', 'neurodevelopmental disorder', 'neuroeducation', 'neuroethics', 'neurogenesis', 'neuroimmunology', 'neuroplasticity', 'neuron', 'neuroscience', 'neurotransmitter', 'neurotrophic factor', 'nucleotide', 'nucleotide sequence', 'nucleus accumbens', 'nurture', 'obsessive compulsive disorder (OCD)', 'occipital lobe', 'olfactory', 'opiate', 'opioid', 'opioid receptors (e.g., mu, delta, kappa)', 'optic nerve', 'optogenetics', 'oxytocin', 'pain receptors', 'parietal lobe', 'Parkinson’s disease', 'perception', 'peripheral nervous system', 'persistent vegetative state', 'pharmacotherapy', 'pituitary gland', 'plasticity', 'positron emission tomography (PET)', 'postsynaptic cell', 'post-traumatic stress disorder (PTSD)', 'prefrontal cortex', 'premotor cortex', 'presynaptic cell', 'prion', 'protein folding', 'psychiatry', 'psychoactive drug', 'psychological dependence', 'psychology', 'psychosis', 'rapid eye movement (REM) sleep', 'receptors', 'recessive', 'recovery of function', 'rehabilitation', 'resting state', 'retina', 'reward/reinforcement brain network', 'reuptake', 'RNA (ribonucleic acid)', 'rod', 'schizophrenia', 'senses', 'serotonin', 'social neuroscience', 'soma', 'somatosensory cortex', 'sonogenetics', 'sono-stimulation', 'spinal cord', 'stem cells', 'stress', 'striatum', 'stroke', 'subgenual cortex', 'substantia nigra', 'subthalamic nucleus', 'sulcus', 'synapse', 'synaptic cleft', 'synaptic pruning', 'synaptic transmission', 'tau protein', 'telomere', 'temporal lobes', 'thalamus', 'Tourette’s syndrome', 'transcranial electrical stimulation (tDCS and tACS)', 'transcranial magnetic stimulation (TMS)', 'traumatic brain injury (TBI)', 'two-photon microscopy', 'ultrasound', 'vagus nerve', 'vagus nerve stimulation', 'vertebral arteries', 'vestibular system', 'visual cortex', 'Wernicke’s area', 'white matter', 'X-ray']

terms = [ 'abdomen', 'abdominal', 'action potential', 'action potential amplitude', 'afferent', 'amygdala', 'anterior', 'arachnoid mater', 'association cortex', 'audition', 'axon', 'axon terminal', 'balance', 'bilayer', 'blood volume', 'brainstem', 'carbohydrate', 'caudal', 'cell body', 'central nervous system', 'cerebellum', 'cerebral cortex', 'cerebral hemispheres', 'cerebrum', 'chemotaxis', 'circuit', 'CNS', 'corpus callosum', 'cranial nerve', 'declarative memory', 'dendrite', 'depolarize', 'disease of learning', 'distal', 'dopamine', 'dorsal', 'dorsal horn', 'dorsal root ganglion (DRG) neurons', 'dura mater', 'electrolytes', 'endocrine system', 'efferent', 'episodic memory', 'EPSP', 'excitatory interneuron', 'excitatory neuron', 'excitatory post-synaptic potential', 'ethics', 'experimental control', 'extracellular', 'feedback', 'feedback loop', 'feed-forward network', 'firing rate', 'frequency', 'frontal cortex', 'frontal lobe', 'ganglion (plural = ganglia)', 'gap junction', 'glands', 'glutamate receptor', 'graded synaptic potential', 'gray matter', 'growth cone', 'gyrus (plural = gyri)', 'head', 'hippocampus', 'homeostasis', 'hyperpolarize', 'hypothalamus', 'inertia', 'inhibitory neuron', 'inhibitory post-synaptic potential', 'interneuron', 'intracellular', 'ion channel', 'ionotropic', 'IPSP', 'labyrinth', 'latency', 'lateral', 'lobe', 'long-term memory', 'lung', 'medial', 'membrane potential', 'memory, declarative', 'memory, episodic', 'memory, procedural', 'memory, semantic', 'meninges', 'merkels discs', 'metabotropic', 'metamorphosis', 'mnemonic', 'motor cortex', 'motor learning', 'motor neuron', 'muscle fiber', 'muscle spindle', 'myelin', 'myelinate', 'negative feedback', 'nerve terminal', 'nervous system', 'neural circuit', 'neural pathway', 'neuroethics', 'neuromarketing', 'neuromuscular junction', 'neuron', 'neuron, excitatory', 'inhibitory neuron', 'neuron, motor', 'neuron, post-synaptic', 'neuron, pre-synaptic', 'neuron, sensory', 'neuronal circuit', 'neuronal network', 'neurotransmitter', 'nucleotide', 'nystagmus', 'occipital lobe', 'olfactory bulb', 'optic chiasm', 'optic nerve', 'parietal lobe', 'pathfinding', 'period', 'peripheral', 'peripheral nervous system', 'pH', 'pia mater', 'pioneer axon', 'pituitary gland', 'PNS', 'positive feedback', 'posterior', 'post-synaptic neuron', 'potassium (K+)', 'prefrontal cortex (PFC)', 'pre-synaptic neuron', 'primacy effect', 'procedural memory', 'pruning', 'proprioception', 'proximal', 'purinergic receptor channels', 'Purkinje cells', 'reaction time', 'recall', 'recency effect', 'receptor', 'recognition', 'refractory period', 'rod', 'rostral', 'semantic memory', 'sensation', 'sensory neuron', 'short-term memory', 'signal transduction pathways', 'smell', 'soma', 'somatosensation', 'spinal cord', 'sprouting', 'sulcus (plural = sulci)', 'synapse', 'taste', 'temporal lobe', 'thalamus', 'thoracic', 'thorax', 'threshold', 'tract', 'transmitter', 'variable', 'ventral', 'ventral horn', 'ventricle', 'vertigo', 'vestibular system', 'vision', 'visual cortex', 'white matter' ]

for term in terms:
    query = term.lower().replace('–', '').replace('  ', ' ').replace('_', ' ').replace(' ', '%20')
    query = query.split('(')[0]
    cmd = 'curl --silent --output /dev/null http://145.14.12.67:6001/api/v1/search/?text='+query
    print(cmd)
    system(cmd)