%% Test

L = detectSpotCenters(ImageTest)
i_molecules
j_molecules

%% Load

load("CoordinatesTest.mat")
load("ImageFloue.mat")
load("ImagesPALM.mat")
load("ImageTest.mat")

% Paramètres
upsampleFactor = 20; % Facteur de suréchantillonnage pour la super-résolution
sigma = 1; % Ecart-type pour la pondération gaussienne
intensityThreshold = 0; % Seuil d'intensité pour ignorer les points faibles

% Initialisation de la matrice d'accumulation haute résolution
[numRows, numCols, numFrames] = size(ImagesPALM);
highResRows = numRows * upsampleFactor;
highResCols = numCols * upsampleFactor;
highResImage = zeros(highResRows, highResCols);

% Définir la PSF gaussienne
gaussianSize = round(6 * sigma);
[x, y] = meshgrid(-gaussianSize:gaussianSize, -gaussianSize:gaussianSize);
gaussianPSF = exp(-(x.^2 + y.^2) / (2 * sigma^2));

% Boucle sur chaque image de la séquence
for k = 1:numFrames
    img = ImagesPALM(:,:,k);
    
    % Détecter les centres des photons
    centers = detectSpotCenters(img);
    
    % Ajouter les localisations de photons avec précision sub-pixellaire
    for i = 1:size(centers, 1)
        % Position haute résolution sans arrondi
        xHighRes = centers(i,1) * upsampleFactor;
        yHighRes = centers(i,2) * upsampleFactor;
        
        % Vérifier l'intensité pour filtrer les points faibles
        if img(round(centers(i,2)), round(centers(i,1))) > intensityThreshold
            % Calculer les indices de position du centre pour le PSF
            xRange = round(xHighRes)-gaussianSize:round(xHighRes)+gaussianSize;
            yRange = round(yHighRes)-gaussianSize:round(yHighRes)+gaussianSize;
            
            % S'assurer que les indices sont dans les limites
            if all(xRange > 0 & xRange <= highResCols) && all(yRange > 0 & yRange <= highResRows)
                % Ajouter la PSF gaussienne autour du centre détecté
                highResImage(yRange, xRange) = highResImage(yRange, xRange) + gaussianPSF;
            end
        end
    end
end

% Redimensionner l'image haute résolution à la taille d'origine
finalImage = highResImage;

% Binariser l'image finale pour isoler les lettres
level = graythresh(finalImage);
binaryImage = imbinarize(finalImage, level);
%binaryImage = finalImage; 

% Appliquer un filtre morphologique pour lisser et réduire le bruit
binaryImage = imclose(binaryImage, strel('disk', 1)); % Fermeture morphologique pour remplir les trous
binaryImage = imopen(binaryImage, strel('disk', 1)); % Ouverture pour réduire les petits bruits

% Afficher l'image finale binarisée et lissée
figure;
imshow(binaryImage);
title('Image binarisée améliorée avec lissage morphologique');

% Afficher l'image finale binarisée et lissée
figure;
imshow(finalImage);
title('Image binarisée améliorée sans lissage morphologique');

% Fonction de détection des centres des spots
function centers = detectSpotCenters(img)
    % Conversion en double si nécessaire
    if ~isa(img, 'double')
        img = im2double(img);
    end
    % Application d'un seuil pour binariser l'image
    level = graythresh(img);
    bw = imbinarize(img, level);
    % Suppression des petits objets (bruit)
    bw = bwareaopen(bw, 4);
    % Étiquetage des régions connectées
    [L, num] = bwlabel(bw);
    props = regionprops(L, 'Centroid');
    % Extraction des coordonnées des centres
    centers = zeros(num, 2);
    for i = 1:num
        centers(i,:) = props(i).Centroid;
    end
end
