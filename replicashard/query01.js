db.messages.aggregate([
        { '$project' : { 'headers.From' : 1, 'headers.To' : 1 } },
        { '$unwind' : '$headers.To' },
        { '$group' : { '_id' : { 'from' : '$headers.From', 'to' : '$headers.To' },
                        'num' : { '$sum' : 1 } } },
        { '$sort' : { 'num' : -1 } },
        { '$limit' : 5 }
])
