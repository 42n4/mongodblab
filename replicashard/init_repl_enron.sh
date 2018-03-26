./init_clean.sh
mongod -f mongodbz1.conf
mongod -f mongodbz2.conf
mongod -f mongodbz3.conf
mongo --port 27101 --eval "rs.initiate( {
   _id : 'z',
   members: [
      { _id: 0, host: 'gen2db:27101' },
      { _id: 1, host: 'gen2db:27102' },
      { _id: 2, host: 'gen2db:27103' }
   ]
});
rs.status();"
sleep 15
mongo --port 27101 --eval "cfg=rs.conf();
cfg.members[0].priority=1;
cfg.members[1].priority=0.8;
cfg.members[2].priority=0.6;
rs.reconfig(cfg);"
sleep 5
mongo --port 27101 --eval "rs.status();"
mongorestore --host z/gen2db:27101,gen2db:27102,gen2db:27103 --drop --db enron ../dump/enron
#mongoimport --host z/gen2db:27101,gen2db:27102,gen2db:27103 -d mydb -c zips < ../zips.json
mongo --host z/gen2db:27101,gen2db:27102,gen2db:27103  enron --eval "db.messages.count()"
mongo --port 27101 enron --eval "db.messages.count()"
