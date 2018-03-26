    import sys
    import pymongo

    def cleanup():

        connection = pymongo.Connection("mongodb://localhost", safe=True)
        db = connection.photos
        images = db.images
        albums = db.albums

        images_cursor = images.find()
           
        for image in images_cursor:

            n_albums = albums.find({'images':image['_id']}).count()
            if (n_albums == 0):
                print "Image "+str(image['_id'])+" is orphan. Removing..."
                images.remove(image)

    cleanup()
