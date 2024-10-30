% Afficher l'image de référence floue
figure;
imshow(ImageFloue);
title('Image de référence floue');

% Reconstruire l'image PALM
fprintf('Début de la reconstruction PALM...\n');
reconstructedImage = reconstructPALM(ImagesPALM);

% Afficher l'image reconstruite
figure;
imshow(reconstructedImage);
title('Image PALM reconstruite');

% Sauvegarder l'image reconstruite
imwrite(reconstructedImage, 'palm_reconstruction.tif');
fprintf('Reconstruction terminée et sauvegardée dans palm_reconstruction.tif\n');

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

% Fonction de reconstruction PALM
function reconstructedImage = reconstructPALM(ImagesPALM, pixelSize)
    % Paramètres
    if nargin < 2
        pixelSize = 0.1; % Taille du pixel dans l'image reconstruite (en unités originales)
    end
    % Déterminer la taille de l'image reconstruite
    [height, width, numFrames] = size(ImagesPALM);
    scaleFactor = 1/pixelSize;
    newHeight = ceil(height * scaleFactor);
    newWidth = ceil(width * scaleFactor);
    % Initialiser l'image reconstruite
    reconstructedImage = zeros(newHeight, newWidth);
    % Traiter chaque image de la séquence
    fprintf('Traitement des images en cours...\n');
    for k = 1:numFrames
        if mod(k, 100) == 0
            fprintf('Image %d/%d\n', k, numFrames);
        end
        % Extraire l'image courante
        currentImage = ImagesPALM(:,:,k);
        % Détecter les centres des spots
        centers = detectSpotCenters(currentImage);
        % Ajouter chaque localisation à l'image reconstruite
        for i = 1:size(centers, 1)
            % Convertir les coordonnées à l'échelle super-résolue
            x = round(centers(i,1) * scaleFactor);
            y = round(centers(i,2) * scaleFactor);
            % Vérifier que les coordonnées sont dans les limites
            if x > 0 && x <= newWidth && y > 0 && y <= newHeight
                % Ajouter un point gaussien
                reconstructedImage(y,x) = reconstructedImage(y,x) + 1;
            end
        end
    end
end
