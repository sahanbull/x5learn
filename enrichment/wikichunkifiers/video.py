import requests
from wikichunkifiers.generic import extract_chunks_from_generic_text
from wikichunkifiers.lib.util import EnrichmentError

X5GON_PLATFORM_URL = "https://platform.x5gon.org/api/v1"

GET_MATERIAL_CONTENTS_LIST_ENDPOINT = "/oer_materials/{}/contents"


def get_text_from_x5gon_material_id(mat_id):
    # get contents of specific material
    contents = requests.get(X5GON_PLATFORM_URL + GET_MATERIAL_CONTENTS_LIST_ENDPOINT.format(mat_id))

    # if endpoint worked correctly
    if contents.status_code == 200:
        contents = contents.json()
        # get plain English translation / transcription
        try:
            contents = [c["value"]["value"]
                        for c in contents["oer_contents"]
                        if c["extension"] == "plain" and c["language"] == "en"]
        except KeyError:
            raise EnrichmentError("No English version of video transcription.")

        if len(contents) > 0:
            text = contents[0]
            if len(text) > 0:
                return text

    raise EnrichmentError("Text extraction caused an error")


def extract_chunks_from_x5gon_video(oer_data):
    """

    Args:
        oer_data {str:val}: a set of key values about the x5gon video material

    Returns:


    """
    # get the text from the x5gon platform
    material_id = oer_data["material_id"]
    text = get_text_from_x5gon_material_id(material_id)

    data = {'title': "",
            'description': text}

    chunks = extract_chunks_from_generic_text("", data)

    return chunks
